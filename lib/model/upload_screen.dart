import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  TextEditingController _commentController = TextEditingController();
  String postId = const Uuid().v4();
  bool _uploading = false;
  final FirebaseFirestore _userRef = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  late String _username;

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showFullScreenImage,
                child: Container(
                  width: 400,
                  height: 500,
                  child: _imageFile == null
                      ? Image.asset('images/46.jpg')
                      : Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // اظهار مربع التعليق فقط إذا تم اختيار صورة
              if (_imageFile != null)
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 224, 220, 185),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Add Comment',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // اظهار أزرار "الكاميرا" و"الاستوديو" إذا لم يتم اختيار صورة
              if (_imageFile == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 224, 220, 185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _takePicture,
                      child: const Text(
                        'Camera',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 224, 220, 185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _selectPicture,
                      child: const Text(
                        'Studio',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // اظهار أزرار "رفع" و"إلغاء" بجانب بعض فقط إذا تم اختيار صورة
              if (_imageFile != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 224, 220, 185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _uploading ? null : _uploadImage,
                      child: _uploading
                          ? CircularProgressIndicator()
                          : const Text(
                              'POST',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 10),

                    // زر "إلغاء" بشكل X
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 224, 220, 185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _cancelSelection,
                      child: const Icon(
                        Icons.close, // شكل X
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage() {
    if (_imageFile != null) {
      _navigateToFullScreenImage();
    }
  }

  Future<void> _getUsername() async {
    try {
      final docSnapshot =
          await _userRef.collection('users').doc(_user!.uid).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _username = userData['name'] ?? '';
        });
      }
    } catch (error) {
      print('Error getting user bio: $error');
    }
  }

  void _navigateToFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(250, 252, 241, 183),
            title: const Text('عرض الصورة'),
          ),
          body: Center(
            child: Image.file(_imageFile!),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectPicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _uploading = true;
    });

    try {
      String imageUrl = await _uploadImageToFirebase(_imageFile!);
      if (imageUrl.isNotEmpty) {
        createPostFirestore(
          mediaUrl: imageUrl,
          description: _commentController.text,
          username: _username,
        );
        _showSnackBar('تم رفع الصورة بنجاح');
        _publishImage();
        setState(() {
          _imageFile = null;
          _commentController.clear();
          _uploading = false;
        });
      } else {
        _showSnackBar('حدث خطأ أثناء رفع الصورة. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('حدث خطأ أثناء رفع الصورة. يرجى المحاولة مرة أخرى.');
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    final Reference ref = storage.ref().child("post_$postId.jpg");
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  final user = FirebaseAuth.instance.currentUser;
  void createPostFirestore(
      {required String mediaUrl,
      required String description,
      required String username}) {
    FirebaseFirestore.instance
        .collection("posts")
        .doc(user!.uid)
        .collection("usersPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": user!.uid,
      "username": username,
      "mediaUrl": mediaUrl,
      "description": description,
      "timestamp": Timestamp.now(),
      "likes": {}
    });
  }

  void _publishImage() {
    // Perform action to publish the image
  }

  void _cancelSelection() {
    setState(() {
      _imageFile = null;
      _commentController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
