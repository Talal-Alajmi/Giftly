import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/pages/EvintAcTivite.dart';
import 'package:giftle/pages/postonly.dart';

import 'package:giftle/wegedt/progreas.dart';
import 'package:timeago/timeago.dart' as timeago;

final user = FirebaseAuth.instance.currentUser;

// ignore: camel_case_types
class Activite_screen extends StatefulWidget {
  @override
  State<Activite_screen> createState() => _Activite_screenState();
}

class _Activite_screenState extends State<Activite_screen> {
  @override
  void initState() {
    super.initState();
    _delayMarkNotificationsAsRead();
  }

  void _delayMarkNotificationsAsRead() async {
    // تعيين مؤقت لمدة ساعة (3600 ثانية)
    Timer(Duration(seconds: 30), () {
      _markNotificationsAsRead(); // تحديث حالة الإشعارات بعد ساعة
    });
  }

  void _markNotificationsAsRead() async {
    var feedItemCollection = FirebaseFirestore.instance
        .collection('feed')
        .doc(user!.uid)
        .collection('feeditem');

    var querySnapshot =
        await feedItemCollection.where('isRead', isEqualTo: false).get();

    for (var doc in querySnapshot.docs) {
      await feedItemCollection.doc(doc.id).update({'isRead': true});
    }
  }

  getfeeditem() {
    return StreamBuilder(
        stream: feedsRef
            .doc(user!.uid)
            .collection('feeditem')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Activtifeeditem> feedsitem = [];
          snapshot.data?.docs.forEach((doc) {
            feedsitem.add(Activtifeeditem.fromDocument(doc));
          });
          return ListView(
            children: feedsitem,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(248, 243, 239, 220),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 224, 220, 185),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Pacifico',
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/48.jpg'),
            ),
          ),
          child: Column(children: <Widget>[
            Expanded(
              child: getfeeditem(),
            ),
          ]),
        ));
  }
}

// ignore: must_be_immutable
class Activtifeeditem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userprofimf;
  final String commentdata;
  final String userIdadd;
  final Timestamp timestamp;
  final String EvindID;
  final bool isRead;

  Activtifeeditem({
    required this.username,
    required this.userIdadd,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    required this.postId,
    required this.commentdata,
    required this.timestamp,
    required this.userprofimf,
    required this.EvindID,
    required this.isRead,
  });

  factory Activtifeeditem.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    var data = doc.data()!;
    return Activtifeeditem(
      postId: data.containsKey("postId") ? data["postId"] : '',
      commentdata: data.containsKey("commentdata") ? data["commentdata"] : '',
      username: data.containsKey("username") ? data["username"] : '',
      mediaUrl: data.containsKey("mediaUrl") ? data["mediaUrl"] : '',
      userprofimf: data.containsKey("userprofimf") ? data["userprofimf"] : '',
      timestamp:
          data.containsKey("timestamp") ? data["timestamp"] : Timestamp.now(),
      type: data.containsKey("type") ? data["type"] : '',
      userId: data.containsKey("userId") ? data["userId"] : '',
      userIdadd: data.containsKey("userIdadd") ? data["userIdadd"] : '',
      EvindID: data.containsKey("EvindID") ? data["EvindID"] : '',
      isRead: data.containsKey("isRead") ? data["isRead"] : true,
    );
  }

  String Activtitemtext = '';

  Widget? mediPreviw;

  configurmediprviw(BuildContext context) {
    if (type == 'Like' || type == 'Comments') {
      mediPreviw = GestureDetector(
        onTap: () {
          shopostonly(context);
        },
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: CachedNetworkImageProvider(mediaUrl),
                    fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      );
    } else if (type == 'Evints') {
      mediPreviw = Container(
        height: 40,
        width: 70,
        child: ElevatedButton(
          onPressed: () {
            shoevent(context);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green, // لون الزر
            padding: EdgeInsets.symmetric(
                horizontal: 1, vertical: 1), // مساحة داخلية
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3), // حواف مستديرة
            ),
          ),
          child: Text(
            'View Event',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      mediPreviw = Text('');
    }

    if (type == 'Like') {
      Activtitemtext = 'Liked your Post';
    } else if (type == 'wishlist') {
      Activtitemtext = 'add wish list cheek him';
    } else if (type == 'Follow') {
      Activtitemtext = 'is Following You';
    } else if (type == 'Comments') {
      Activtitemtext = 'Replied: $commentdata';
    } else if (type == 'Evints') {
      Activtitemtext = 'invited you to an event';
    } else {
      Activtitemtext = 'Error : $type';
    }
  }

  shopostonly(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Postonly(postId: postId, userId: userId);
    }));
  }

  shoevent(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EvintAcTivite(EvindID: EvindID, userIdadd: userIdadd);
    }));
  }

  shoProfil(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Profile(profilid: userIdadd);
    }));
  }

  @override
  Widget build(BuildContext context) {
    var textColor = isRead ? Color.fromARGB(255, 104, 98, 98) : Colors.black;
    configurmediprviw(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Column(
        children: [
          Container(
            child: ListTile(
              leading: GestureDetector(
                onTap: (() {
                  shoProfil(context);
                }),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(userprofimf),
                ),
              ),
              titleAlignment: ListTileTitleAlignment.center,
              title: GestureDetector(
                onTap: () {
                  shoProfil(context);
                },
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                          color: textColor,
                          shadows: [
                            Shadow(
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              subtitle: Text(
                '$Activtitemtext',
                style: TextStyle(
                  fontFamily: 'Pacifico',
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.grey,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: mediPreviw,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 72,
              ),
              Text(
                timeago.format(timestamp.toDate()),
                style: TextStyle(
                  fontFamily: 'Pacifico',
                  fontWeight: FontWeight.bold,
                  fontSize: 8.0,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
