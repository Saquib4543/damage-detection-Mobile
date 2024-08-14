import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

// Import for web
import 'package:universal_html/html.dart' as html;

class ImageUploadService {
  static const AUTH_API_ENDPOINT = 'https://uat.iailclaimftr.com/api/V1/auth';
  static const API_ENDPOINT = 'https://uat.iailclaimftr.com/api/V1/rc';

  // Hardcoded authentication details
  static const String username = "gAAAAABfqhmdiVzoGThMkYkX1wKTlbK_yh1XLdECahns85T9XhNl7Lff3I-frOyn8gGoWSctvVTw-4woa8gkRly9RQPZz6n67w==";
  static const String password = "gAAAAABfqhmdiVzoGThMkYkX1wKTlbK_yh1XLdECahns85T9XhNl7Lff3I-frOyn8gGoWSctvVTw-4woa8gkRly9RQPZz6n67w==";

  Future<String> getAuthToken() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json'
    };

    final body = json.encode({
      'username': username,
      'password': password,
    });

    try {
      final response = await http.post(
        Uri.parse(AUTH_API_ENDPOINT),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['access_token'] is String) {
          return jsonResponse['access_token'] as String;
        } else {
          throw Exception('Invalid access token format');
        }
      } else {
        throw Exception('Failed to authenticate. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  MediaType detectImageMediaType(Uint8List imageData) {
    if (imageData.isEmpty || imageData.length < 8) {
      return MediaType('application', 'octet-stream');
    }

    if (imageData.sublist(0, 2).toString() == '[255, 216]') {
      return MediaType('image', 'jpeg');
    }

    if (imageData.sublist(0, 8).toString() ==
        '[137, 80, 78, 71, 13, 10, 26, 10]') {
      return MediaType('image', 'png');
    }

    return MediaType('application', 'octet-stream');
  }

  Future<Map<String, dynamic>> uploadImage(dynamic image) async {
    if (kIsWeb) {
      return _uploadImageWeb(image as Uint8List);
    } else {
      return _uploadImageMobile(image as File);
    }
  }

  Future<Map<String, dynamic>> _uploadImageWeb(Uint8List imageData) async {
    final token = await getAuthToken();
    final blob = html.Blob([imageData]);
    final form = html.FormData();
    final Completer<Map<String, dynamic>> completer = Completer();

    String accessKey = 'd452aee4-e372-456f-a30e-77e007fdcca5';
    form.append('access_key', accessKey);

    String filename = 'somefilename.png';
    form.appendBlob('rc_page_1', blob, filename);

    final assetBlob = await loadImageAsset('assets/dummy.jpg');
    form.appendBlob('rc_page_2', assetBlob, 'somefile.png');

    final request = html.HttpRequest();
    request.open('POST', API_ENDPOINT);

    String authToken = 'JWT $token';
    request.setRequestHeader('Authorization', authToken);
    request.send(form);

    request.onLoadEnd.listen((event) {
      if (request.status == 200) {
        print("Uploaded! Response: ${request.responseText}");
        Map<String, dynamic> jsonResponse = json.decode(request.responseText!);
        completer.complete(jsonResponse);
      } else {
        print("Not uploaded! Status: ${request.status}, Reason: ${request.statusText}, Response: ${request.responseText}");
        completer.completeError("Upload failed with status: ${request.status}");
      }
    });

    request.onError.listen((event) {
      print("Error occurred: ${event}");
      completer.completeError("Error occurred during upload");
    });

    return completer.future;
  }

  Future<Map<String, dynamic>> _uploadImageMobile(File imageFile) async {
    final token = await getAuthToken();

    var request = http.MultipartRequest('POST', Uri.parse(API_ENDPOINT));
    request.headers['Authorization'] = 'JWT $token';
    request.fields['access_key'] = 'd452aee4-e372-456f-a30e-77e007fdcca5';

    request.files.add(await http.MultipartFile.fromPath('rc_page_1', imageFile.path));

    final dummyImagePath = await _saveDummyImage();
    request.files.add(await http.MultipartFile.fromPath('rc_page_2', dummyImagePath));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print("Uploaded!");
        String responseBody = await response.stream.bytesToString();
        return json.decode(responseBody);
      } else {
        print("Not uploaded!");
        throw Exception('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during image upload: $e');
    }
  }

  Future<String> saveImageAndGetPath(Uint8List imageData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final File imgFile = File('$path/$fileName');
    await imgFile.writeAsBytes(imageData);
    return imgFile.path;
  }

  Future<String> _saveDummyImage() async {
    final dummyImageBytes = await rootBundle.load('assets/dummy.jpg');
    return await saveImageAndGetPath(dummyImageBytes.buffer.asUint8List(), 'dummy.jpg');
  }

  Future<html.Blob> loadImageAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    return html.Blob([bytes]);
  }

  // Future<Map<String, dynamic>> sendRcRegNumber(String rcRegNumber) async {
  //   print(rcRegNumber);
  //   final Uri apiUrl = Uri.parse('https://kyc-api.aadhaarkyc.io/api/v1/rc/rc-full');
  //   String token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY1MTQ3MjA3OCwianRpIjoiN2Y1ZjAzNmEtNDBlMC00NDFlLWE4NzYtMWFjMGU5YWE2OTUyIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmlhaWxAYWFkaGFhcmFwaS5pbyIsIm5iZiI6MTY1MTQ3MjA3OCwiZXhwIjoxOTY2ODMyMDc4LCJ1c2VyX2NsYWltcyI6eyJzY29wZXMiOlsicmVhZCJdfX0.Uv7arJdKKhug-6k60H4ovD1VxW1LuDLVcfX5iiKQQs4';
  //
  //   try {
  //     final response = await http.post(
  //       apiUrl,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: json.encode({
  //         'id_number': rcRegNumber,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print('Successfully sent data to the API!');
  //       print(response);
  //       print(response.body);
  //       return json.decode(response.body);
  //     } else {
  //       print('Failed to send data. Status code: ${response.statusCode}');
  //       throw Exception('Failed to send RC number. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error sending RC number: $e');
  //   }
  // }

  Future<Map<String, dynamic>> sendRcRegNumber(String rcRegNumber) async {
    print(rcRegNumber);
    final Uri apiUrl = Uri.parse('https://kyc-api.aadhaarkyc.io/api/v1/rc/rc-full');
    String token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY1MTQ3MjA3OCwianRpIjoiN2Y1ZjAzNmEtNDBlMC00NDFlLWE4NzYtMWFjMGU5YWE2OTUyIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmlhaWxAYWFkaGFhcmFwaS5pbyIsIm5iZiI6MTY1MTQ3MjA3OCwiZXhwIjoxOTY2ODMyMDc4LCJ1c2VyX2NsYWltcyI6eyJzY29wZXMiOlsicmVhZCJdfX0.Uv7arJdKKhug-6k60H4ovD1VxW1LuDLVcfX5iiKQQs4';

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_number': rcRegNumber,
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully sent data to the API!');
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        print(jsonResponse);
        return jsonResponse;
      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        throw Exception('Failed to send RC number. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending RC number: $e');
    }
  }

}