import 'dart:convert';
import 'package:damagedetection1/AvailableClaims.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class otpenter extends StatefulWidget {
  final String mobileNumber;

  const otpenter({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<otpenter> createState() => _otpenterState();
}

class _otpenterState extends State<otpenter> {
  final otpControllers = List.generate(4, (_) => TextEditingController());
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(Icons.arrow_back, color: Colors.blue[900]),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "OTP VERIFICATION",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Please Enter the OTP sent to your Mobile Number",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return _textFieldOTP(index: index);
                  }),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator(color: Colors.yellow)
                    : FloatingActionButton.extended(
                  label: Text('Verify',
                      style: TextStyle(color: Colors.blue[900])),
                  backgroundColor: Colors.yellow,
                  onPressed: _validateOTP,
                  shape: RoundedRectangleBorder(
                    side:
                    BorderSide(color: Colors.blue[900]!, width: 2.0),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Did Not Receive OTP?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // Implement resend OTP functionality here
                  },
                  child: Text(
                    "Resend OTP",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textFieldOTP({required int index}) {
    return Container(
      height: 85,
      child: AspectRatio(
        aspectRatio: 0.7,
        child: TextField(
          controller: otpControllers[index],
          autofocus: index == 0,
          onChanged: (value) {
            if (value.length == 1) {
              FocusScope.of(context).nextFocus();
            }
            if (value.length == 0 && index != 0) {
              FocusScope.of(context).previousFocus();
            }
          },
          showCursor: false,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counter: Offstage(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.blue),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _validateOTP() async {
    setState(() {
      _isLoading = true;
    });

    final otp = otpControllers.map((controller) => controller.text).join();
    final mobileNumber = widget.mobileNumber;

    final apiUrl = 'http://164.52.211.138:6001/login/verify-otp';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'OTP': otp,
          'mobile_number': mobileNumber,
        }),
      );

      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (responseData['message'] == 'Login successful') {
          final token = responseData['token'];
          print('Received Token: $token');

          // Store token in SharedPreferences
          try {
            // SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            bool success = await prefs.setString('auth_token', token);
            if (success) {

              print('Token stored successfully');
            } else {
              print('Failed to store token');
            }
          } catch (e) {
            print('Error storing token: $e');
          }

          Get.to(AvailableClaims());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Invalid OTP. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: ${responseData['error'] ?? 'Please try again.'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: ${error.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
