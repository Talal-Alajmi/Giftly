import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/pages/UserDataService.dart';
import 'package:giftle/wegedt/progreas.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Usser? user;
  bool isLoading = false;
  TextEditingController controllerDisplayName = TextEditingController();
  TextEditingController controllerBio = TextEditingController();
  bool _validBio = true;
  bool _validDisplayName = true;
  final _scaffKey = GlobalKey<ScaffoldState>();
  final picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });
      DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
      if (doc.exists) {
        user = Usser.fromDocument(doc);
        controllerDisplayName.text = user!.name;
        controllerBio.text = user!.bio;
      } else {
        print("User not found");
      }
    } catch (e) {
      print("Error getting user data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Container buildProfileImage() {
    return Container(
      padding: EdgeInsets.only(top: 20.0),
      child: GestureDetector(
        onTap: () => _pickImage(ImageSource.gallery),
        child: Stack(
          children: [
            Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: ClipOval(
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: user!.photoUrl,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container textFieldDisplayName() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              "Display Name",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextField(
            controller: controllerDisplayName,
            decoration: InputDecoration(
                hintText: "Display Name",
                errorText: _validDisplayName ? null : "Display Name too Short"),
          )
        ],
      ),
    );
  }

  Container textFieldBio() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              "Bio",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextField(
            controller: controllerBio,
            decoration: InputDecoration(
                hintText: "Bio", errorText: _validBio ? null : "Bio too Long"),
          )
        ],
      ),
    );
  }

  Future<void> updateProfileData() async {
    setState(() {
      _validDisplayName = controllerDisplayName.text.trim().length >= 3 &&
          controllerDisplayName.text.isNotEmpty;

      _validBio = controllerBio.text.trim().length <= 100;
    });

    if (_validBio && _validDisplayName) {
      try {
        // تحميل الصورة إلى Firebase Storage
        if (_imageFile != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_profile_images')
              .child(widget.currentUserId)
              .child('image.jpg');
          await ref.putFile(_imageFile!);
          final imageUrl = await ref.getDownloadURL();

          // تحديث مسار الصورة في قاعدة البيانات Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .update({'photoUrl': imageUrl});
        }

        // تحديث باقي بيانات المستخدم
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .update({
          "displayname": controllerDisplayName.text,
          "bio": controllerBio.text
        });
        Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile Updated")),
          );
        }
      } catch (error) {
        print("Error updating profile: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      key: _scaffKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Text("Edit Profile"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.done),
              onPressed: () {
                updateProfileData();
                Navigator.pop(context);
              })
        ],
      ),
      body: isLoading
          ? circularProgress()
          : user != null
              ? ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        buildProfileImage(),
                        textFieldDisplayName(),
                        textFieldBio(),
                        Padding(padding: EdgeInsets.all(10.0)),
                      ],
                    )
                  ],
                )
              : Container(),
    );
  }
}
