// import 'package:flutter/material.dart';
//
// class AssetImageExample extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Asset Image Example'),
//       ),
//       body: Center(
//         child: Builder(
//           builder: (BuildContext context) {
//             return FutureBuilder(
//               future: _checkAssetExists(context, 'assets/TimePhoto_20240713_181526.jpg'),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.done) {
//                   if (snapshot.hasError) {
//                     return Text('Error: ${snapshot.error}');
//                   } else {
//                     return Image.asset('assets/TimePhoto_20240713_181526.jpg');
//                   }
//                 } else {
//                   return CircularProgressIndicator();
//                 }
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> _checkAssetExists(BuildContext context, String assetPath) async {
//     try {
//       final image = AssetImage(assetPath);
//       await precacheImage(image, context);
//       print('Asset $assetPath loaded successfully.');
//     } catch (e) {
//       print('Error loading asset $assetPath: $e');
//     }
//   }
// }
