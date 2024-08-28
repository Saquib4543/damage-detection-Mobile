import 'dart:convert';
import 'package:damagedetection1/ClaimStepperForm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'AvailableClaims.dart';
import 'GoogleMapScreen.dart';
import 'otp.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  print('Retrieved token: $token'); // Debug statement
    runApp(MyApp(initialRoute:token !=null ?'/availableClaims':'/login'));

}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Damage Detection',
      theme: ThemeData(
        primaryColor: Color(0xFF00008B),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFF00008B, {
            50: Color(0xFFE6E6FA),
            100: Color(0xFFCDCDFF),
            200: Color(0xFFB4B4FF),
            300: Color(0xFF9A9AFF),
            400: Color(0xFF8080FF),
            500: Color(0xFF6666FF),
            600: Color(0xFF4C4CFF),
            700: Color(0xFF3333FF),
            800: Color(0xFF1A1AFF),
            900: Color(0xFF00008B),
          }),
          accentColor: Colors.yellow,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/availableClaims', page: () => AvailableClaims()),
        GetPage(name: '/claimform', page: () => ClaimFormStepper()),
        GetPage(name: '/map', page: () => GoogleMapScreen()),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final phoneNumber = "+91${_phoneController.text}";
      final apiUrl = "http://164.52.211.138:6001/login/check-number";

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'CUST_MOBILE': phoneNumber,
          }),
        );

        if (response.statusCode == 200) {
          print(response.body);
          final responseBody = jsonDecode(response.body);
          if (responseBody['status'] == 'OTP sent') {
            Get.to(() => otpenter(mobileNumber: phoneNumber));
          } else {
            _showErrorDialog(responseBody['message'] ?? 'Login failed');
          }
        } else {
          _showErrorDialog('Your Number is not associated with any policies');
        }
      } catch (e) {
        _showErrorDialog('An error occurred: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Error", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 30),
                  Text(
                    'Please Enter Your Phone Number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      prefix: Text("+91  "),
                      prefixIcon: Icon(Icons.phone, color: Colors.blue[900]),
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.blue[900]),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator(
                    color: Colors.yellow,
                  )
                      : FloatingActionButton.extended(
                    label: Text(
                      'Enter',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue[900],
                    onPressed: _login,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
