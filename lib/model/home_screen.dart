import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/pages/pagepost.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // إضافة هذا الاستيراد
import 'package:url_launcher/url_launcher.dart'; // إضافة هذا الاستيراد

final currentUser = FirebaseAuth.instance.currentUser?.uid;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> posts = [];
  bool isLoading = true;
  List<String> adImages = [
    'images/bag.jpg',
    'images/cov.jpg',
    'images/watch.jpg',
    'images/bag.jpg',
    'images/cov.jpg',
    'images/watch.jpg',
  ];
  ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  bool _forward = true; // تحديد اتجاه الحركة
  Timer? _timer;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _startTimer();
    getProfilePosts();
    _storeDeviceToken(); // إضافة هذا الاستدعاء
    _checkForUpdate(); // إضافة هذا الاستدعاء
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_forward) {
        if (_currentImageIndex < adImages.length - 1) {
          _currentImageIndex++;
        } else {
          _forward = false;
          _currentImageIndex--;
        }
      } else {
        if (_currentImageIndex > 0) {
          _currentImageIndex--;
        } else {
          _forward = true;
          _currentImageIndex++;
        }
      }
      _scrollController.animateTo(
        _currentImageIndex * 70.0, // عرض الصورة مع بعض الفسحة
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  Future<void> getProfilePosts() async {
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('usersPosts')
          .orderBy("timestamp", descending: true)
          .orderBy('ownerId')
          .get();

      if (postsSnapshot.docs.isNotEmpty) {
        setState(() {
          posts =
              postsSnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
        });
      } else {
        print('لا توجد منشورات لعرضها');
      }
    } catch (error) {
      print('حدث خطأ أثناء جلب المنشورات: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _storeDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .update({'deviceToken': token}).catchError((error) {
        print("Failed to update device token: $error");
      });
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('appInfo')
          .doc('version')
          .get();

      final latestVersion = snapshot['latestVersion'];
      final currentVersion = '1.0.4+5';

      if (currentVersion != latestVersion) {
        final updateUrl = snapshot['updateUrl'];
        if (updateUrl != null && updateUrl.isNotEmpty) {
          _promptUserToUpdate(updateUrl);
        } else {
          print("Update URL is not available");
        }
      }
    } catch (e) {
      print("Error fetching Firestore data: $e");
    }
  }

  void _promptUserToUpdate(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(),
      ),
      Scaffold(
        backgroundColor:
            Color.fromARGB(248, 243, 239, 220), // اجعل خلفية الـ Scaffold شفافة
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            '𝓖𝓲𝓯𝓽 𝓛𝓮',
            style: TextStyle(
                fontFamily: 'Copperplate',
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              Color.fromARGB(248, 243, 236, 199), // اجعل الـ AppBar شفافًا
          elevation: 0, // إزالة الظل
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 15,
            ),
            Container(
              height: 80.0,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: adImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 80,
                        width: 120.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(adImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: posts.isNotEmpty
                  ? ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          margin: EdgeInsets.all(5),
                          child: Column(
                            children: [
                              posts[index],
                            ],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text('No Posts'),
                    ), // عرض رسالة في حالة عدم وجود منشورات
            ),
          ],
        ),
      ),
    ]);
  }
}
