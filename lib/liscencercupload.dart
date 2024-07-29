import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:damagedetection1/extractionapi.dart';
import 'package:get/get.dart';
import 'package:damagedetection1/displayinfo.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> with TickerProviderStateMixin {
  Uint8List? _imageData;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _pickImage({bool useCamera = false}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _imageData = file.readAsBytesSync();
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.yellow,
      end: Color(0xFF0D47A1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Please Upload your RC', style: TextStyle(color: Colors.yellow)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoading) ...[
              CircularProgressIndicator(
                valueColor: _colorAnimation,
              ),
              SizedBox(height: 20),
              Text('Validating...'),
            ] else if (_imageData != null) ...[
              Image.memory(_imageData!),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Upload', style: TextStyle(color: Color(0xFF0D47A1))),
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    print("Starting image upload");
                    Map responseText = await ImageUploadService().uploadImage(_imageData!);
                    print("Finished image upload");
                    print(responseText);

                    String rcRegNumber = responseText['result']['output']['rc_reg_number'];
                    print("RC Number: $rcRegNumber");

                    var vahaan_response = await ImageUploadService().sendRcRegNumber(rcRegNumber);
                    print(vahaan_response);
                    final data = json.decode(vahaan_response);
                    final selectedData = data['data'].entries.where((entry) {
                      return entry.key != 'client_id';
                    }).map((entry) {
                      if (entry.value == null) {
                        return MapEntry(entry.key, 'No Data Present');
                      }
                      return entry;
                    }).toList();

                    Get.to(() => DetailPage(selectedEntries: selectedData));
                  } catch (e) {
                    print("Error: $e");
                    _showSnackBar("Error: $e");
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                child: Text('Retake', style: TextStyle(color: Color(0xFF0D47A1))),
                onPressed: () {
                  setState(() {
                    _imageData = null;
                  });
                },
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                ),
              ),
            ] else ...[
              ElevatedButton(
                child: Text('Choose from Gallery', style: TextStyle(color: Color(0xFF0D47A1))),
                onPressed: () => _pickImage(),
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                child: Text('Take a Photo', style: TextStyle(color: Color(0xFF0D47A1))),
                onPressed: () => _pickImage(useCamera: true),
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:damagedetection1/extractionapi.dart';
// import 'package:get/get.dart';
// import 'package:damagedetection1/displayinfo.dart';
//
// import 'extractionapi_mobile.dart';
//
// class ImageUploadPage extends StatefulWidget {
//   @override
//   _ImageUploadPageState createState() => _ImageUploadPageState();
// }
//
// class _ImageUploadPageState extends State<ImageUploadPage> with TickerProviderStateMixin {
//   final TextEditingController _rcController = TextEditingController();
//   bool _isLoading = false;
//   late AnimationController _controller;
//   late Animation<Color?> _colorAnimation;
//
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   void _showSnackBar(String message) {
//     final snackBar = SnackBar(content: Text(message));
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }
//
//   void _processRcNumber(String rcNumber) async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       var vahaan_response = await ImageUploadService().sendRcRegNumber(rcNumber);
//       print("Raw response: $vahaan_response");
//
//       dynamic decodedResponse = json.decode(vahaan_response);
//       print("Decoded response: $decodedResponse");
//
//       List<MapEntry<String, dynamic>> selectedData = [];
//
//       if (decodedResponse is Map<String, dynamic> && decodedResponse.containsKey('data')) {
//         var data = decodedResponse['data'];
//         if (data is Map<String, dynamic>) {
//           selectedData = data.entries.where((entry) => entry.key != 'client_id')
//               .map((entry) => MapEntry(entry.key, entry.value ?? 'No Data Present'))
//               .toList();
//         } else if (data is List) {
//           // Handle case where data is a List
//           selectedData = data.asMap().entries
//               .map((entry) => MapEntry(entry.key.toString(), entry.value ?? 'No Data Present'))
//               .toList();
//         }
//       } else if (decodedResponse is List) {
//         // Handle case where the entire response is a List
//         selectedData = decodedResponse.asMap().entries
//             .map((entry) => MapEntry(entry.key.toString(), entry.value ?? 'No Data Present'))
//             .toList();
//       }
//
//       if (selectedData.isNotEmpty) {
//         Get.to(DetailPage(selectedEntries: selectedData));
//       } else {
//         _showSnackBar("No valid data found in the response");
//       }
//     } catch (e) {
//       print("Error: $e");
//       _showSnackBar("Error: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }  @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     )..repeat(reverse: true); // This makes the animation go back and forth
//
//     _colorAnimation = ColorTween(
//       begin: Colors.yellow,
//       end: Color(0xFF0D47A1),
//     ).animate(_controller);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: Text('Please Upload your RC', style: TextStyle(color: Colors.yellow)),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             if (_isLoading) ...[
//               CircularProgressIndicator(
//                 valueColor: _colorAnimation,
//               ),
//               SizedBox(height: 20),
//               Text('Validating...'),
//             ] else ...[
//               TextField(
//                 controller: _rcController,
//                 decoration: InputDecoration(
//                   labelText: 'Enter RC Number',
//                 ),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   String rcNumber = _rcController.text.trim();
//                   if (rcNumber.isNotEmpty) {
//                     _processRcNumber(rcNumber);
//                   } else {
//                     _showSnackBar("Please enter a valid RC number");
//                   }
//                 },
//                 style: ButtonStyle(
//                   elevation: MaterialStateProperty.all(0),
//                   backgroundColor: MaterialStateProperty.all(Colors.yellow),
//                 ),
//                 child: Text('Submit', style: TextStyle(color: Color(0xFF0D47A1))),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
