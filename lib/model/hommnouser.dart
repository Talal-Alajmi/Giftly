// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:giftle/pages/pagepost.dart';

// class VisitorScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Visitor Posts'),
//       ),
//       body: VisitorPosts(),
//     );
//   }
// }

// class VisitorPosts extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collectionGroup('usersPosts')
//           .orderBy("timestamp", descending: true)
//           .orderBy('ownerId')
//           .snapshots(),
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('حدث خطأ أثناء جلب المنشورات'));
//         } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(child: Text('لا توجد منشورات لعرضها'));
//         } else {
//           List<Post> posts =
//               snapshot.data!.docs.map((doc) => Post.fromDocument(doc)).toList();
//           return ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (BuildContext context, int index) {
//               return posts[index];
//             },
//           );
//         }
//       },
//     );
//   }
// }





















// import 'dart:async';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:uuid/uuid.dart';
// import 'package:camera/camera.dart';

// class CameraPage extends StatefulWidget {
//   const CameraPage({Key? key}) : super(key: key);

//   @override
//   _CameraPageState createState() => _CameraPageState();
// }

// class _CameraPageState extends State<CameraPage> {
//   late CameraController _controller;
//   File? _imageFile;
//   TextEditingController _commentController = TextEditingController();
//   String postId = const Uuid().v4();
//   bool _uploading = false;
//   final FirebaseFirestore _userRef = FirebaseFirestore.instance;
//   final _user = FirebaseAuth.instance.currentUser;

//   late String _username;

//   @override
//   void initState() {
//     super.initState();
//     _getUsername();
//     _initializeCamera();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(child: Text('Up Post')),
//       ),
//       body: Stack(
//         children: [
//           _controller.value.isInitialized
//               ? Container(
//                   height: MediaQuery.of(context).size.height,
//                   width: MediaQuery.of(context).size.width,
//                   child: CameraPreview(_controller))
//               : Container(),
//           Align(
//             alignment: Alignment.bottomRight,
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     onPressed: _selectPicture,
//                     icon: Icon(Icons.photo_library, color: Colors.white),
//                   ),
//                   SizedBox(height: 20),
//                   GestureDetector(
//                     onTap: _takePicture,
//                     child: Center(
//                       child: CircleAvatar(
//                         radius: 40,
//                         backgroundColor: Colors.blueGrey[900],
//                         child: Icon(Icons.camera_alt, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           _imageFile != null
//               ? GestureDetector(
//                   onTap: _showFullScreenImage,
//                   child: Container(
//                     width: double.infinity,
//                     height: double.infinity,
//                     color: Colors.black,
//                     child: Image.file(
//                       _imageFile!,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 )
//               : Container(),
//           Positioned(
//             bottom: 20,
//             left: MediaQuery.of(context).size.width / 2 - 50,
//             child: _imageFile != null
//                 ? ElevatedButton(
//                     onPressed: _uploading ? null : _uploadImage,
//                     child: _uploading
//                         ? CircularProgressIndicator()
//                         : Text('رفع الصورة'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blueGrey[900],
//                     ),
//                   )
//                 : Container(),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     final backCamera = cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.back,
//     );

//     _controller = CameraController(
//       backCamera,
//       ResolutionPreset.high,
//     );

//     await _controller.initialize();

//     if (!mounted) return;

//     setState(() {});
//   }

//   Future<void> _getUsername() async {
//     try {
//       final docSnapshot =
//           await _userRef.collection('users').doc(_user!.uid).get();
//       if (docSnapshot.exists) {
//         final userData = docSnapshot.data() as Map<String, dynamic>;

//         setState(() {
//           _username = userData['name'] ?? '';
//         });
//       }
//     } catch (error) {
//       print('Error getting user bio: $error');
//     }
//   }

//   void _takePicture() async {
//     try {
//       XFile picture = await _controller.takePicture();
//       setState(() {
//         _imageFile = File(picture.path);
//       });
//     } catch (e) {
//       print('Error taking picture: $e');
//     }
//   }

//   Future<void> _selectPicture() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.getImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _uploadImage() async {
//     setState(() {
//       _uploading = true;
//     });

//     try {
//       String imageUrl = await _uploadImageToFirebase(_imageFile!);
//       if (imageUrl.isNotEmpty) {
//         createPostFirestore(
//           mediaUrl: imageUrl,
//           description: _commentController.text,
//           username: _username,
//         );
//         _showSnackBar('تم رفع الصورة بنجاح');
//         _publishImage();
//         setState(() {
//           _imageFile = null;
//           _commentController.clear();
//           _uploading = false;
//         });
//       } else {
//         _showSnackBar('حدث خطأ أثناء رفع الصورة. يرجى المحاولة مرة أخرى.');
//       }
//     } catch (e) {
//       print('Error uploading image: $e');
//       _showSnackBar('حدث خطأ أثناء رفع الصورة. يرجى المحاولة مرة أخرى.');
//     } finally {
//       setState(() {
//         _uploading = false;
//       });
//     }
//   }

//   Future<String> _uploadImageToFirebase(File imageFile) async {
//     final FirebaseStorage storage = FirebaseStorage.instance;
//     final Reference ref = storage.ref().child("post_$postId.jpg");
//     await ref.putFile(imageFile);
//     return await ref.getDownloadURL();
//   }

//   final user = FirebaseAuth.instance.currentUser;
//   void createPostFirestore(
//       {required String mediaUrl,
//       required String description,
//       required String username}) {
//     FirebaseFirestore.instance
//         .collection("posts")
//         .doc(user!.uid)
//         .collection("usersPosts")
//         .doc(postId)
//         .set({
//       "postId": postId,
//       "ownerId": user!.uid,
//       "username": username,
//       "mediaUrl": mediaUrl,
//       "description": description,
//       "timestamp": Timestamp.now(),
//       "likes": {}
//     });
//   }

//   void _publishImage() {
//     // Perform action to publish the image
//   }

//   void _cancelSelection() {
//     setState(() {
//       _imageFile = null;
//       _commentController.clear();
//     });
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   void _showFullScreenImage() {
//     if (_imageFile != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => Scaffold(
//             backgroundColor: Colors.black,
//             appBar: AppBar(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//             ),
//             body: Center(
//               child: Image.file(_imageFile!),
//             ),
//           ),
//         ),
//       );
//     }
//   }
// }
