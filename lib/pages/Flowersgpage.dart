import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/wegedt/progreas.dart';

class Flowersgpage extends StatefulWidget {
  final String profilid;

  Flowersgpage({required this.profilid});

  @override
  State<Flowersgpage> createState() =>
      _FlowersgpageState(profilid: this.profilid);
}

class _FlowersgpageState extends State<Flowersgpage> {
  final String profilid;

  _FlowersgpageState({required this.profilid});

  Widget buildflong() {
    return StreamBuilder(
      stream: followersRef
          .doc(widget.profilid)
          .collection('userfolloers')
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<Future<Followers>> futureFloinfs = snapshot.data!.docs.map((doc) {
          return Followers.fromDocument(doc);
        }).toList();

        return FutureBuilder<List<Followers>>(
          future: Future.wait(futureFloinfs),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return circularProgress();
            }

            List<Followers> floinfs = futureSnapshot.data!;

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
            'Followers',
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

class Followers extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final Timestamp timestamp;

  Followers({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.timestamp,
  });

  static Future<Followers> fromDocument(DocumentSnapshot doc) async {
    DocumentSnapshot snapshot = await usersRef.doc(doc['userId']).get();

    // استخراج معلومات المستخدم
    var userData = snapshot.data() as Map<String, dynamic>;
    var userPhotoUrl = userData['photoUrl'];
    var usernamee = userData['name'];

    return Followers(
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
