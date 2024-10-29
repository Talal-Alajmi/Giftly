import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftle/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

final wishRef = FirebaseFirestore.instance.collection("Wishlist");

class Wish extends StatefulWidget {
  final String profilid;

  Wish({
    required this.profilid,
  });

  @override
  _WishState createState() => _WishState();
}

class _WishState extends State<Wish> {
  late ImagePicker _imagePicker;
  late TextEditingController _commentController;
  File? _imageFile;
  bool _isLoading = false;

  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    _commentController = TextEditingController();
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImageWithComment() async {
    if (_imageFile != null) {
      setState(() {
        _isLoading = true; // إظهار مؤشر التحميل
      });

      final comment = _commentController.text.trim();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final destination = 'images/$fileName';

      try {
        final ref = FirebaseStorage.instance.ref(destination);
        await ref.putFile(_imageFile!);
        final imageUrl = await ref.getDownloadURL();

        await wishRef.add({
          'profilid': widget.profilid,
          'comment': comment,
          'imageUrl': imageUrl,
        });
        DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

        // استخراج معلومات المستخدم
        var userData = snapshot.data() as Map<String, dynamic>;
        var userPhotoUrl = userData['photoUrl'];
        var username = userData['name'];

        // جلب قائمة المتابعين للمستخدم
        final followersSnapshot = await followersRef
            .doc(widget.profilid)
            .collection('userfolloers')
            .get();

        for (var doc in followersSnapshot.docs) {
          final followerId = doc.id;

          // إضافة إشعار لكل متابع
          await feedsRef.doc(followerId).collection('feeditem').doc().set({
            'type': 'wishlist',
            'username': username,
            'userId': widget.profilid,
            'userprofimf': userPhotoUrl,
            'timestamp': Timestamp.now(),
            'commentdata': '',
            'userIdadd': currentUser,
            'isRead': false
          });
        }

        setState(() {
          _imageFile = null;
          _commentController.clear();
        });
        setState(() {
          _isLoading = false; // إخفاء مؤشر التحميل بعد انتهاء العملية
        });
      } catch (e) {
        // Handle errors if any
        print(e);
      }
    }
  }

  Future<void> _deleteImage(String docId, String imageUrl) async {
    try {
      // حذف الصورة من Firebase Storage
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      // حذف الوثيقة من Firestore
      await wishRef.doc(docId).delete();
    } catch (e) {
      // Handle errors if any
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Text('My Wish List'),
        actions: [
          widget.profilid == currentUser
              ? IconButton(
                  icon: Icon(Icons.photo_library),
                  onPressed: _getImageFromGallery,
                )
              : Container(),
          widget.profilid == currentUser
              ? IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _getImageFromCamera,
                )
              : Container(),
        ],
      ),
      body: Stack(children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Add a comment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            maxLines: 1,
                          ),
                          SizedBox(height: 10.0),
                          ElevatedButton(
                            onPressed: _uploadImageWithComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15.0),
                              child: Center(
                                child: Text(
                                  'Add to Wish List',
                                  style: TextStyle(
                                      fontSize: 16.0, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 10.0),
                  Container(
                    child: Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: wishRef
                            .where('profilid', isEqualTo: widget.profilid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final docs = snapshot.data!.docs;
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final docId = docs[index].id;
                                return Card(
                                  shadowColor: Colors.green,
                                  surfaceTintColor: Colors.green,
                                  margin: EdgeInsets.symmetric(vertical: 10.0),
                                  child: ListTile(
                                    leading: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageScreen(
                                                imageUrl: data['imageUrl']),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: CachedNetworkImage(
                                          imageUrl: data['imageUrl'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(data['comment']),
                                    trailing: widget.profilid == currentUser
                                        ? PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert),
                                            onSelected: (String result) {
                                              if (result == 'delete') {
                                                _deleteImage(
                                                    docId, data['imageUrl']);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) =>
                                                    <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ]),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  ImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wish'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}
