import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/wegedt/progreas.dart';

class Floingpage extends StatefulWidget {
  final String profilid;

  Floingpage({required this.profilid});

  @override
  State<Floingpage> createState() => _FloingpageState(profilid: this.profilid);
}

class _FloingpageState extends State<Floingpage> {
  final String profilid;

  _FloingpageState({required this.profilid});

  Widget buildflong() {
    return StreamBuilder(
      stream: followeingRef
          .doc(widget.profilid)
          .collection('userfolloers')
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<Future<Folloing>> futureFloinfs = snapshot.data!.docs.map((doc) {
          return Folloing.fromDocument(doc);
        }).toList();

        return FutureBuilder<List<Folloing>>(
          future: Future.wait(futureFloinfs),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return circularProgress();
            }

            List<Folloing> floinfs = futureSnapshot.data!;

            return ListView.builder(
              itemCount: floinfs.length,
              itemBuilder: (context, index) {
                return floinfs[index];
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Center(
          child: Text(
            'Following',
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
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildflong(),
          ),
          Divider(),
        ],
      ),
    );
  }
}

class Folloing extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final Timestamp timestamp;

  Folloing({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.timestamp,
  });

  static Future<Folloing> fromDocument(DocumentSnapshot doc) async {
    DocumentSnapshot snapshot = await usersRef.doc(doc['userId']).get();

    // استخراج معلومات المستخدم
    var userData = snapshot.data() as Map<String, dynamic>;
    var userPhotoUrl = userData['photoUrl'];
    var usernamee = userData['name'];

    return Folloing(
      username: usernamee,
      userId: doc['userId'],
      avatarUrl: userPhotoUrl,
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(profilid: userId),
              ),
            );
          },
          title: Text(username),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              child: Row(
                children: [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
