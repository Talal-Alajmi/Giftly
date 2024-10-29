import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/wegedt/progreas.dart';
import 'package:timeago/timeago.dart' as timeago;

class comments extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String mediaUrl;
  comments(
      {required this.postId, required this.mediaUrl, required this.ownerId});

  @override
  State<comments> createState() => _commentsState(
        postId: this.postId,
        mediaUrl: this.mediaUrl,
        ownerId: this.ownerId,
      );
}

class _commentsState extends State<comments> {
  final String postId;
  final String ownerId;
  final String mediaUrl;

  _commentsState(
      {required this.postId, required this.mediaUrl, required this.ownerId});

  TextEditingController commentController = new TextEditingController();
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  void initializePage() {
    debugPrint('Page initialized with postId: $postId');
  }

  buildcomment() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .doc(postId)
          .collection('comments')
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          handleError(snapshot.error);
          return circularProgress();
        }
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data?.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  void addcomment(String userName, String userFoto) {
    String commentText = commentController.text.trim();
    if (commentText.isNotEmpty && commentText.length <= 100) {
      final userId = user?.uid;
      if (userId != null) {
        commentsRef.doc(postId).collection('comments').add({
          'username': userName,
          'comments': commentText,
          'timestamp': DateTime.now(),
          'userId': userId,
          'avataFotourl': userFoto
        }).then((value) {
          if (userId != ownerId) {
            feedsRef.doc(ownerId).collection('feeditem').add({
              'type': 'Comments',
              'commentdata': commentText,
              'username': userName,
              'userId': ownerId,
              'userprofimf': userFoto,
              'postId': postId,
              'mediaUrl': mediaUrl,
              'userIdadd': userId,
              'timestamp': Timestamp.now(),
              'isRead': false
            });
            commentController.clear();
            setState(() {
              hasError = false;
            });
          }
        }).catchError((error) {
          handleError(error);
        });
      }
    }
  }

  void handleError(error) {
    setState(() {
      hasError = true;
    });
    debugPrint('Error occurred: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Center(child: Text('Comment')),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return circularProgress();
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return circularProgress(); // عرض مؤشر التحميل إذا كانت بيانات المستخدم غير موجودة
          }
          final userName = userData['name'] ?? '';
          final userfoto = userData['photoUrl'] ?? '';
          return Column(
            children: <Widget>[
              Expanded(
                child: buildcomment(),
              ),
              Divider(),
              ListTile(
                title: TextFormField(
                  controller: commentController,
                  maxLength: 100,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'add comment',
                    filled: true,
                    fillColor: Color.fromARGB(255, 224, 220, 185),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        addcomment(userName, userfoto);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  Comment(
      {required this.username,
      required this.userId,
      required this.avatarUrl,
      required this.comment,
      required this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avataFotourl'],
      comment: doc['comments'],
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
                  builder: (context) => Profile(
                        profilid: userId,
                      )),
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
                children: [
                  Column(
                    children: [
                      Text(
                        timeago.format(timestamp.toDate()),
                        style: TextStyle(fontSize: 8),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 65,
            ),
            Column(
              children: [
                Container(width: 150, child: Text(comment)),
                SizedBox(
                  width: 30,
                )
              ],
            ),
          ],
        )
      ],
    );
  }
}
