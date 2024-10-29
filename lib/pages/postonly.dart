import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/pages/pagepost.dart';
import 'package:giftle/wegedt/progreas.dart';

class Postonly extends StatelessWidget {
  final String postId;
  final String userId;
  Postonly({required this.postId, required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: postsRef.doc(userId).collection('usersPosts').doc(postId).get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return circularProgress();
        }
        if (snapshot.hasData && snapshot.data != null) {
          Post post = Post.fromDocument(snapshot.data!);
          return Scaffold(
            backgroundColor: Color.fromARGB(248, 243, 239, 220),
            appBar: AppBar(
                backgroundColor: Color.fromARGB(248, 243, 236, 199),
                title: Center(
                  child: Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                )),
            body: ListView(
              children: [
                Container(
                  child: post,
                ),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
