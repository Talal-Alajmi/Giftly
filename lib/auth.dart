import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giftle/model/activite_screen.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/model/search_screen.dart';
import 'package:giftle/model/upload_screen.dart';
import 'package:giftle/pages/Login_Screen.dart';
import 'package:giftle/model/home_screen.dart';

final usersRef = FirebaseFirestore.instance.collection("users");
final postsRef = FirebaseFirestore.instance.collection("posts");
final wishRef = FirebaseFirestore.instance.collection("Wishlist");
final commentsRef = FirebaseFirestore.instance.collection("comments");
final feedsRef = FirebaseFirestore.instance.collection("feed");
final followersRef = FirebaseFirestore.instance.collection("followers");
final followeingRef = FirebaseFirestore.instance.collection("followeing");
final user = FirebaseAuth.instance.currentUser;

class Auoth extends StatefulWidget {
  const Auoth({super.key});

  @override
  State<Auoth> createState() => _AuothState();
}

class _AuothState extends State<Auoth> {
  PageController pagecontroller = PageController();
  int pageIndex = 0;
  int notificationCount = 0; // عدد الإشعارات غير المقروءة

  final usersRef = FirebaseFirestore.instance.collection("users");
  final postsRef = FirebaseFirestore.instance.collection("posts");

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndx) {
    pagecontroller.jumpToPage(pageIndx);
  }

  @override
  void initState() {
    super.initState();
    _updateNotificationCount();
  }

  void _updateNotificationCount() {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('feed')
          .doc(user!.uid)
          .collection('feeditem')
          .where('isRead',
              isEqualTo:
                  false) // افترض وجود حقل 'isRead' لتحديد قراءة الإشعارات
          .snapshots()
          .listen((snapshot) {
        setState(() {
          notificationCount =
              snapshot.docs.length; // تحديث عدد الإشعارات غير المقروءة
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              body: PageView(
                controller: pagecontroller,
                onPageChanged: onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  HomeScreen(),
                  Activite_screen(),
                  CameraPage(),
                  SearchUserPage(
                      currentUserID:
                          FirebaseAuth.instance.currentUser?.uid ?? ''),
                  Profile(
                    profilid: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                ],
              ),
              bottomNavigationBar: CurvedNavigationBar(
                backgroundColor: Color.fromARGB(248, 243, 239, 220),
                color: Color.fromARGB(255, 224, 220, 185),
                animationDuration: Duration(microseconds: 300),
                onTap: onTap,
                items: [
                  Icon(Icons.home_sharp),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none),
                      if (notificationCount >
                          0) // إظهار العدد إذا كان أكبر من 0
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '$notificationCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Icon(Icons.camera_alt),
                  Icon(Icons.search),
                  Icon(Icons.person),
                ],
              ),
            );
          } else {
            return const LoginScreen();
          }
        }),
      ),
    );
  }
}
