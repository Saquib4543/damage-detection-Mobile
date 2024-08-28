import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'PDFOverlay.dart';
import 'form_sections.dart';
import 'liscencercupload.dart';

class ClaimFormStepper extends StatefulWidget {
  @override
  _ClaimFormStepperState createState() => _ClaimFormStepperState();
}

class _ClaimFormStepperState extends State<ClaimFormStepper> {
  int _currentStep = 0;
  bool _agreeToTerms = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    for (var section in formSections) {
      String sectionTitle = section.keys.first;
      _formData[sectionTitle] = {};
      for (var field in section.values.first) {
        String fieldName = field is Map ? field['field'] : field;
        _formData[sectionTitle]![fieldName] = null;
      }
    }
    print('Initialized form data: $_formData');
  }




  List<Map<String, Object>> _getSteps() {
    List<Map<String, Object>> steps = formSections.asMap().entries.map((entry) {
      int idx = entry.key;
      Map<String, List<dynamic>> section = entry.value;
      String title = section.keys.first;
      return {
        'title': title,
        'fields': section.values.first,
        'index': idx,
      };
    }).toList();

    steps.add({
      'title': 'Declaration',
      'isDeclaration': true,
      'index': steps.length,
    });
    return steps;
  }

  Widget _buildStepContent(Map<String, Object> step) {
    if (step['isDeclaration'] == true) {
      return Column(
        children: [
          Text(
            'I hereby declare that the information provided is true and accurate to the best of my knowledge.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          CheckboxListTile(
            title: Text('I agree to the terms and conditions'),
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      );
    } else {
      String sectionTitle = step['title'] as String;
      return Column(
        children: ((step['fields'] as List<dynamic>?) ?? []).map((field) {
          String fieldName = field is Map<String, dynamic> ? field['field'] as String : field.toString();
          String fieldType = field is Map<String, dynamic> ? field['type'] as String : 'text';

          switch (fieldType) {
            case 'boolean':
              return CheckboxListTile(
                title: Text(fieldName),
                value: _formData[sectionTitle]![fieldName] ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    _formData[sectionTitle]![fieldName] = value;
                    print('Updated $fieldName in $sectionTitle to $value');
                  });
                },
              );
            case 'date':
              return _buildDateField(sectionTitle, fieldName);
            case 'time':
              return _buildTimeField(sectionTitle, fieldName);
            default:
              return _buildTextField(sectionTitle, fieldName, fieldType);
          }
        }).toList(),
      );
    }
  }

  Widget _buildTextField(String sectionTitle, String fieldName, String fieldType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        key: Key('${sectionTitle}_$fieldName'),
        decoration: InputDecoration(
          labelText: fieldName,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Color(0xFF1A237E)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
        initialValue: _formData[sectionTitle]![fieldName]?.toString(),
        onChanged: (value) {
          setState(() {
            _formData[sectionTitle]![fieldName] = value;
            print('Updated $fieldName in $sectionTitle to $value');
          });
        },
        keyboardType: _getKeyboardType(fieldType),
        validator: _getValidator(fieldType),
      ),
    );
  }

  Widget _buildDateField(String sectionTitle, String fieldName) {
    return ListTile(
      title: Text(fieldName),
      subtitle: Text(
        _formData[sectionTitle]![fieldName] != null
            ? DateFormat('yyyy-MM-dd').format(_formData[sectionTitle]![fieldName])
            : 'Select Date',
        style: TextStyle(color: Colors.black),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _formData[sectionTitle]![fieldName] ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != _formData[sectionTitle]![fieldName]) {
          setState(() {
            _formData[sectionTitle]![fieldName] = picked;
            print('Updated $fieldName in $sectionTitle to $picked');
          });
        }
      },
    );
  }

  Widget _buildTimeField(String sectionTitle, String fieldName) {
    return ListTile(
      title: Text(fieldName),
      subtitle: Text(_formData[sectionTitle]![fieldName] != null
          ? _formData[sectionTitle]![fieldName].format(context)
          : 'Select Time'),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _formData[sectionTitle]![fieldName] ?? TimeOfDay.now(),
        );
        if (picked != null && picked != _formData[sectionTitle]![fieldName]) {
          setState(() {
            _formData[sectionTitle]![fieldName] = picked;
            print('Updated $fieldName in $sectionTitle to $picked');
          });
        }
      },
    );
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  String? Function(String?)? _getValidator(String fieldType) {
    switch (fieldType) {
      case 'email':
        return (value) {
          if (value == null ||
              value.isEmpty ||
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        };
      case 'number':
        return (value) {
          if (value == null || value.isEmpty || int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        };
      default:
        return null;
    }
  }

  void _scrollToStep(int stepIndex) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final stepWidth = renderBox.size.width / 4; // Assuming 4 steps visible at a time
    _scrollController.animateTo(
      stepIndex * stepWidth,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Map<String, dynamic> mapFormDataToApiFormat(Map<String, Map<String, dynamic>> formData) {
    String formatTimeOfDay(TimeOfDay timeOfDay) {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
      return DateFormat('HH:mm').format(dateTime);
    }

    return {
      "ref_id": "4567890", // Adjust as needed
      "policy_number": formData["Insured Details"]!["Policy / Cover Note No"] ?? "",
      "full_name": formData["Insured Details"]!["Name"] ?? "",
      "loss_type": "Accident", // Set as appropriate
      "claim_number": "", // Adjust as needed
      "permanent_address_line1": formData["Insured Details"]!["Permanent Address"] ?? "",
      "permanent_address_line2": "", // Not present in form data
      "city_district": formData["Insured Details"]!["City"] ?? "",
      "state": formData["Insured Details"]!["State"] ?? "",
      "country": "India", // Adjust as needed
      "pincode": formData["Insured Details"]!["Pin Code"] ?? "",
      "mobile": formData["Insured Details"]!["Mobile No"] ?? "",
      "email": formData["Insured Details"]!["Email ID"] ?? "",
      "date_of_registration": formData["Vehicle Details"]!["Date of Registration"]?.toIso8601String() ?? "",
      "registration_number": formData["Vehicle Details"]!["Registration Number"] ?? "",
      "engine_number": formData["Vehicle Details"]!["Engine Number"] ?? "",
      "chassis_number": formData["Vehicle Details"]!["Chassis Number"] ?? "",
      "make_of_vehicle": formData["Vehicle Details"]!["Make of Vehicle"] ?? "",
      "model": formData["Vehicle Details"]!["Model"] ?? "",
      "odometer_reading": formData["Vehicle Details"]!["Odometer Reading"] ?? 0,
      "driver_full_name": formData["Driver Details"]!["Driver Name"] ?? "",
      "gender": formData["Insured Details"]!["Gender"] ?? "",
      "date_of_birth": formData["Insured Details"]!["Date of Birth"]?.toIso8601String() ?? "",
      "driving_license_number": formData["Driver Details"]!["Driving License Number"] ?? "",
      "license_issuing_authority": formData["Driver Details"]!["License Issuing Authority"] ?? "",
      "license_expiry_date": formData["Driver Details"]!["License Date of Expiry"]?.toIso8601String() ?? "",
      "license_for_vehicle_type": formData["Driver Details"]!["License for Type of Vehicle"] ?? "",
      "temporary_license": formData["Driver Details"]!["Was the license temporary?"] ?? false,
      "relation_with_insured": formData["Driver Details"]!["Relation with Insured"] ?? "",
      "employment_duration": formData["Driver Details"]!["If paid driver, how long has he been in your employment?"] ?? 0,
      "under_influence": formData["Driver Details"]!["Was he under the influence of intoxicating liquor or drugs?"] ?? false,
      "endorsements_or_suspensions": "", // Not present in form data
      "date_of_accident": formData["Accident Details"]!["Date of Accident"]?.toIso8601String() ?? "",
      "time_of_accident": formData["Accident Details"]!["Time of Accident"] != null
          ? formatTimeOfDay(formData["Accident Details"]!["Time of Accident"])
          : "",
      "speed_of_vehicle": formData["Accident Details"]!["Speed of Vehicle (Kmph)"] ?? "",
      "number_of_occupants": formData["Accident Details"]!["No. of Occupants / Pillion rider"] ?? "",
      "location_of_accident": "", // Add if available
      "description_of_accident": "", // Add if available
      "reported_to_police": false, // Add if available
      "not_reported_reason": "", // Add if available
      "police_station_name": "", // Add if available
      "fir_number": "", // Add if available
      "garage_name": formData["Garage Details"]!["Garage Name"] ?? "",
      "garage_contact_person": formData["Garage Details"]!["Garage Contact Person and Address"] ?? "",
      "garage_address": "", // Not present in form data
      "garage_phone_number": formData["Garage Details"]!["Garage Phone Number"] ?? "",
      "fitness_valid_upto": "", // Add if available
      "load_carried_at_accident_time": "", // Add if available
      "permit_valid_upto": "", // Add if available
      "injury_name": "", // Add if available
      "injury_phone_number": "", // Add if available
      "nature_of_injury": "", // Add if available
      "injury_capacity": "", // Add if available
      "injury_address": "", // Add if available
      "description_of_damage": "", // Add if available
      "date_of_theft": "", // Add if available
      "time_of_theft": "", // Add if available
      "place_of_theft": "", // Add if available
      "circumstances_of_theft": "", // Add if available
      "items_stolen": "", // Add if available
      "estimated_cost_of_replacement": "", // Add if available
      "thef_discoverd_reported_by": "", // Add if available
      "theft_reported_to_police": false, // Add if available
      "theft_police_station_name": "", // Add if available
      "theft_fir_number": "", // Add if available
      "thef_fir_date": "", // Add if available
      "thef_fir_time": "", // Add if available
      "thef_attending_inspector": "", // Add if available
      "bank_name": "", // Add if available
      "account_number": "", // Add if available
      "ifsc_micr_code": "", // Add if available
      "account_holder_name": "", // Add if available
      "vehicle_repair_satisfaction": "", // Add if available
      "claim_discharge_voucher": "", // Add if available
      "signature_thumb_impression": null, // Add if available
      "declaration_date": DateTime.now().toIso8601String(),
      "declaration_place": "Your City" // Set as needed
    };
  }

  Future<void> saveFormData(Map<String, Map<String, dynamic>> formData) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(formData);
    await prefs.setString('formData', jsonData);
    print('Form data saved to SharedPreferences: $jsonData');
  }
  // Map<String, Map<String, dynamic>> formData
  Future<void> _submitForm() async {
    saveFormData(_formData);
    // File pdfFile = await PDFOverlay.createOverlay(_formData);
    //
    // // Navigate to a new page to display or share the PDF
    // Get.to(() => PDFViewerPage(pdfFile: pdfFile));
    Get.to(() => ImageUploadPage());

    // final apiUrl = 'http://164.52.202.251/fw_damage/submit_claim_form'; // Replace with your API endpoint
    //
    // final payload = mapFormDataToApiFormat(formData);
    //
    // // Convert DateTime to ISO8601 string manually
    // final payloadWithFormattedDates = payload.map((key, value) {
    //   if (value is DateTime) {
    //     return MapEntry(key, value.toIso8601String());
    //   }
    //   return MapEntry(key, value);
    // });
    //
    // final response = await http.post(
    //   Uri.parse(apiUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode(payloadWithFormattedDates),
    // );
    //
    // if (response.statusCode == 200) {
    //   print('Data successfully sent to API.');
    // } else {
    //   print('Failed to send data. Status code: ${response.statusCode}');
    //   print('Response body: ${response.body}');
    // }
  }

  // void _submitForm() {
  //   print('Form Data: $_formData');
  //   // Implement your form submission logic here
  // }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();

    return Scaffold(
      appBar: AppBar(
        title: Text('Claim Form',style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF1A237E),
        elevation: 0,
      ),
      backgroundColor: Colors.white, // Set background color to white
      body: Column(
        children: [
          Container(
            height: 80,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width / 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: _currentStep >= index ? Color(0xFF1A237E) : Colors.grey,
                        child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        steps[index]['title'].toString(),
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildStepContent(steps[_currentStep]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                        _scrollToStep(_currentStep);
                      });
                    },
                    child: Text('Back', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A237E)),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < steps.length - 1) {
                      setState(() {
                        _currentStep++;
                        _scrollToStep(_currentStep);
                      });
                    } else {
                      if (_agreeToTerms) {
                        _submitForm();
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please agree to the terms and conditions before submitting',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                  child: Text(_currentStep < steps.length - 1 ? 'Next' : 'Submit',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A237E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
