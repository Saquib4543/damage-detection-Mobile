import 'dart:convert';
import 'package:damagedetection1/ClaimStepperForm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AvailableClaims extends StatefulWidget {
  @override
  _AvailableClaimsState createState() => _AvailableClaimsState();
}

class _AvailableClaimsState extends State<AvailableClaims> {
  List<Map<String, String>> claims = [];

  @override
  void initState() {
    super.initState();
    fetchClaims();
  }

  Future<void> fetchClaims() async {
    final url = 'http://164.52.211.138:6001/breakins?mobile_number=%2B919700905643';
    final token = await getToken();
    print('Token: $token');
    if (token == null) {
      print('Token is null');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Body: ${response.body}'); // For debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['breakins'] != null && data['breakins'] is Map<String, dynamic>) {
          setState(() {
            claims = (data['breakins'] as Map<String, dynamic>).entries.map((entry) {
              final breakin = entry.value as Map<String, dynamic>;

              return {
                'claimId': breakin['BREAKIN_ID']?.toString() ?? 'N/A',
                'claimName': breakin['CUST_NAME']?.toString() ?? 'N/A',
                'insuranceCompany': breakin['INSURANCE_COMPANY']?.toString() ?? 'N/A',
                'policyEffectiveDate': breakin['POLICY_EFFECTIVE_DATE']?.toString() ?? 'N/A',
                'policyExpiryDate': breakin['POLICY_EXPIRY_DATE']?.toString() ?? 'N/A',
                'engineNo': breakin['ENGINE_NO']?.toString() ?? 'N/A',
                'chassisNo': breakin['CHASSIS_NO']?.toString() ?? 'N/A',
                'email': breakin['CUST_EMAIL']?.toString() ?? 'N/A',
                'mobile': breakin['CUST_MOBILE']?.toString() ?? 'N/A',
                'pincode': breakin['PIN_CODE']?.toString() ?? 'N/A',
                'state': breakin['CUST_STATE_NAME']?.toString() ?? 'N/A',
                'city': breakin['CUST_CITY_NAME']?.toString() ?? 'N/A',
              };
            }).toList();
          });
        } else {
          print('Unexpected data format: ${data['breakins']}');
        }
      } else {
        print('Failed to load claims: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to load claims: $error');
    }
  }

  void _logout() async {
    // Show confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false when Cancel is pressed
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true when Logout is pressed
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // Proceed with logout if user confirmed
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      Get.offAllNamed('/login');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Claims', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: claims.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: claims.length,
        itemBuilder: (context, index) {
          final claim = claims[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claim ID: ${claim['claimId']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow('Customer Name', claim['claimName']),
                  _buildDetailRow('Insurance Company', claim['insuranceCompany']),
                  _buildDetailRow('Policy Effective Date', claim['policyEffectiveDate']),
                  _buildDetailRow('Policy Expiry Date', claim['policyExpiryDate']),
                  _buildDetailRow('Engine No', claim['engineNo']),
                  _buildDetailRow('Chassis No', claim['chassisNo']),
                  _buildDetailRow('Email', claim['email']),
                  _buildDetailRow('City', claim['city']),
                  _buildDetailRow('State', claim['state']),
                  _buildDetailRow('Mobile', claim['mobile']),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => ClaimFormStepper(), arguments: {'claim': claim});
                      },
                      child: Text('Claim', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}