import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cameraimageupload.dart';
import 'helpers/getCurrentPosition.dart';

class SelfInspection extends StatefulWidget {
  @override
  State<SelfInspection> createState() => _SelfInspectionState();
}

class _SelfInspectionState extends State<SelfInspection> {
  final ImagePicker _picker = ImagePicker();

  // Image data
  String frontSide = "";
  String frontRightHandSide = "";
  String driverSide = "";
  String rearRightHandSide = "";
  String rearSide = "";
  String rearLeftHandSide = "";
  String passengerSide = "";
  String frontLeftHandSide = "";
  String engineCompart = "";
  String chassisNo = "";
  String odometerCar = "";
  String regCert = "";
  String inspectionCert = "";
  String optional1 = "";
  String optional2 = "";

  // Timestamps and locations
  Map<String, DateTime> timestamps = {};
  Map<String, String> locations = {};

  bool showSubmit = false;
  bool uploading = false;

  Future<String?> fetchJwtToken() async {
    final String authApiUrl = "YOUR_AUTH_API_ENDPOINT_HERE";

    try {
      final response = await http.post(Uri.parse(authApiUrl));
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        return responseMap["token"];
      } else {
        print('Failed to fetch JWT token. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching JWT token: $e');
      return null;
    }
  }

  Future<http.Response> sendImageToApi(String imagePath, String jwtToken) async {
    final String apiUrl = "http://164.52.202.251/fw_damage/create_fw_claim";

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestData = jsonEncode({'image': base64Image});

    return await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: requestData,
    );
  }

  Future<void> _submitImages() async {
    List<String> images = [
      frontSide,
      frontRightHandSide,
      driverSide,
      rearRightHandSide,
      rearSide,
      rearLeftHandSide,
      passengerSide,
      frontLeftHandSide,
      engineCompart,
      chassisNo,
      odometerCar,
    ];

    String? jwtToken = await fetchJwtToken();
    if (jwtToken == null) {
      print("Failed to fetch JWT token!");
      return;
    }

    for (String imagePath in images) {
      if (imagePath.isNotEmpty) {
        final response = await sendImageToApi(imagePath, jwtToken);

        if (response.statusCode == 200) {
          print('Successfully uploaded image: $imagePath');
        } else {
          print('Error uploading image: $imagePath with status: ${response.statusCode}');
        }
      }
    }
  }

  void disableSubmit() {
    if (frontSide.isNotEmpty &&
        frontRightHandSide.isNotEmpty &&
        driverSide.isNotEmpty &&
        rearRightHandSide.isNotEmpty &&
        rearSide.isNotEmpty &&
        rearLeftHandSide.isNotEmpty &&
        passengerSide.isNotEmpty &&
        frontLeftHandSide.isNotEmpty &&
        engineCompart.isNotEmpty &&
        chassisNo.isNotEmpty &&
        odometerCar.isNotEmpty) {
      setState(() {
        showSubmit = true;
      });
    }
  }

  void updateSingleImage(int idx, String path, DateTime time, String location) {
    setState(() {
      switch (idx) {
        case 0:
          frontSide = path;
          break;
        case 1:
          frontRightHandSide = path;
          break;
        case 2:
          driverSide = path;
          break;
        case 3:
          rearRightHandSide = path;
          break;
        case 4:
          rearSide = path;
          break;
        case 5:
          rearLeftHandSide = path;
          break;
        case 6:
          passengerSide = path;
          break;
        case 7:
          frontLeftHandSide = path;
          break;
        case 8:
          engineCompart = path;
          break;
        case 9:
          chassisNo = path;
          break;
        case 10:
          odometerCar = path;
          break;
      }
      timestamps[path] = time;
      locations[path] = location;
    });
    disableSubmit();
  }

  void updateCameraImages(List<Map<String, String>> imageData) {
    setState(() {
      for (var data in imageData) {
        String imgPath = data["imgPath"] ?? "";
        DateTime timestamp = DateTime.parse(data["timestamp"] ?? "");
        String location = data["location"] ?? "";

        if (frontSide.isEmpty) frontSide = imgPath;
        else if (frontRightHandSide.isEmpty) frontRightHandSide = imgPath;
        else if (driverSide.isEmpty) driverSide = imgPath;
        else if (rearRightHandSide.isEmpty) rearRightHandSide = imgPath;
        else if (rearSide.isEmpty) rearSide = imgPath;
        else if (rearLeftHandSide.isEmpty) rearLeftHandSide = imgPath;
        else if (passengerSide.isEmpty) passengerSide = imgPath;
        else if (frontLeftHandSide.isEmpty) frontLeftHandSide = imgPath;
        else if (engineCompart.isEmpty) engineCompart = imgPath;
        else if (chassisNo.isEmpty) chassisNo = imgPath;
        else if (odometerCar.isEmpty) odometerCar = imgPath;

        timestamps[imgPath] = timestamp;
        locations[imgPath] = location;
      }
    });
    disableSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Are you sure you want to go back?"),
            content: Text("Going back will revert all your progress done till now"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("No"),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.yellow,
              title: Text(
                "Self Inspection",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              iconTheme: IconThemeData(color: Colors.black),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Take the vehicle image using camera",
                    style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                  ),
                  ElevatedButton(
                    child: Text(
                      odometerCar.isEmpty ? 'Take Images' : 'Retake Images',
                      style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Text("Image Upload Instructions"),
                          content: Text(
                            "The photos to be captured in proper day-light and open area only. Please do not click the photos in covered area such as garages, underground & parking areas etc.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CameraImageUpload(
                                      updateImageData: updateCameraImages,
                                      showTopBanner: false,
                                      appBarTitle: "",
                                      updateSingleImageData: (_, __, ___, ____) {},
                                      singleImageIndex: 0,
                                    ),
                                  ),
                                );
                              },
                              child: Text("Continue"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.yellow),
                    ),
                  ),
                  if (odometerCar.isNotEmpty) ...[
                    buildImageSection("Front Side", frontSide, 0),
                    buildImageSection("Front RightHand Side", frontRightHandSide, 1),
                    buildImageSection("Driver Side", driverSide, 2),
                    buildImageSection("Rear RightHand Side", rearRightHandSide, 3),
                    buildImageSection("Rear Side", rearSide, 4),
                    buildImageSection("Rear LeftHand Side", rearLeftHandSide, 5),
                    buildImageSection("Passenger Side", passengerSide, 6),
                    buildImageSection("Front LeftHand Side", frontLeftHandSide, 7),
                    buildImageSection("Engine Compart", engineCompart, 8),
                    buildImageSection("Chassis Number", chassisNo, 9),
                    buildImageSection("Odometer Car", odometerCar, 10),
                  ],
                  SizedBox(height: 35),
                  if (showSubmit)
                    ElevatedButton(
                      child: Text(
                        "Submit Form",
                        style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                      ),
                      onPressed: () async {
                        setState(() {
                          uploading = true;
                        });
                        await _submitImages();
                        setState(() {
                          uploading = false;
                        });
                        // Navigate to next screen or show success message
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (uploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.yellow),
                    SizedBox(height: 15),
                    Text(
                      "Uploading Images...",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildImageSection(String title, String imagePath, int index) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[900]),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                  elevation: MaterialStateProperty.all(0),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CameraImageUpload(
                        updateImageData: (List<Map<String, String>> _) {},
                        showTopBanner: true,
                        appBarTitle: title,
                        updateSingleImageData: updateSingleImage,
                        singleImageIndex: index,
                      ),
                    ),
                  );
                },
                child: Text("Retake", style: TextStyle(color: Colors.blue[900])),
              )
            ],
          ),
          if (imagePath.isNotEmpty) ...[
            Image.file(File(imagePath)),
            Text(
              "Timestamp: ${timestamps[imagePath]}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Location: ${locations[imagePath]}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          SizedBox(height: 24),
        ],
      ),
    );
  }

  void navigateToCameraImageUpload({required bool isSingle, required String title, required int index}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraImageUpload(
          updateImageData: updateCameraImages,
          showTopBanner: !isSingle,
          appBarTitle: title,
          updateSingleImageData: updateSingleImage,
          singleImageIndex: index,
        ),
      ),
    );
  }
}
