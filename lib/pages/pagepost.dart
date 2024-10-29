import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/pages/commentpage.dart';

import 'package:giftle/wegedt/progreas.dart';
import 'package:share/share.dart';

import '../auth.dart';

final user = FirebaseAuth.instance.currentUser;

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String description;
  final String mediaUrl;
  final dynamic likes;
  late final String currentUser = FirebaseAuth.instance.currentUser!.uid;

  Post({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.description,
    required this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    Map<dynamic, dynamic> likes = doc["likes"] ?? {};

    return Post(
      postId: doc["postId"],
      ownerId: doc["ownerId"],
      username: doc["username"],
      mediaUrl: doc["mediaUrl"],
      likes: likes,
      description: doc['description'],
    );
  }

  get imageUrl => null;

  int getLikesCount(Map<dynamic, dynamic> likes) {
    if (likes.isEmpty) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((value) {
      if (value == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        description: this.description,
        mediaUrl: this.mediaUrl,
      );
}

class _PostState extends State<Post> {
  bool showCaption = false;
  late String postId;
  late String ownerId;
  late String username;
  late String description;
  late String mediaUrl;
  late int likecount;
  late final String currentUser = FirebaseAuth.instance.currentUser!.uid;
  late bool _isliked = widget.likes[widget.currentUser] == true;

  _PostState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.description,
    required this.mediaUrl,
  });

  @override
  void initState() {
    super.initState();
    likecount = widget.getLikesCount(widget.likes);
    postId = widget.postId;
    ownerId = widget.ownerId;
    _isliked = widget.likes[widget.currentUser] == true;
  }

  bildpostheadr() {
    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(widget.ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userPhotoUrl = userData['photoUrl'] ?? '';
        final username = userData['displayname'] ?? '';
        final userid = userData['id'] ?? '';

        return Column(
          children: <Widget>[
            SizedBox(
              height: 5,
            ),
            Row(
              children: [
                SizedBox(
                  width: 5,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(profilid: userid),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.fromARGB(255, 208, 231, 207), // لون الإطار
                        width: 1.0, // سماكة الإطار
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(userPhotoUrl),
                      backgroundColor: Colors.black,
                      radius: 17,
                    ),
                  ),
                ),
                SizedBox(width: 10), // مساحة بين الصورة والنص
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(profilid: userid),
                      ),
                    );
                  },
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(), // يملأ الفراغ ويدفع الأيقونة إلى اليسار
                if (widget.ownerId ==
                    currentUser) // تحقق من كون المستخدم هو صاحب البوست
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _showDeleteDialog(); // عرض نافذة الحذف عند الضغط على الأيقونة
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  addLikeToActivity() async {
    // جلب معلومات المستخدم
    DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

    // استخراج معلومات المستخدم
    var userData = snapshot.data() as Map<String, dynamic>;
    var userPhotoUrl = userData['photoUrl'];
    var username = userData['name'];
    if (currentUser == ownerId) {
      print('User is liking their own post, no notification will be sent.');
      return; // الخروج من الدالة بدون إرسال إشعار
    }
    // تحديث مجموعة البيانات في Firestore
    try {
      await feedsRef.doc(ownerId).collection('feeditem').doc(postId).set({
        'type': 'Like',
        'username': username,
        'userId': ownerId,
        'userprofimf': userPhotoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': Timestamp.now(),
        'commentdata': '',
        'userIdadd': currentUser,
        'isRead': false
      });
    } catch (error) {
      print('Error adding like to activity: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding like to activity')),
      );
    }
  }

  removLikeToActivity() {
    feedsRef.doc(ownerId).collection('feeditem').doc(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handllikepost() {
    if (_isliked) {
      FirebaseFirestore.instance
          .collection("posts")
          .doc(ownerId)
          .collection("usersPosts")
          .doc(postId)
          .update({'likes.$currentUser': false});
      removLikeToActivity();

      setState(() {
        likecount -= 1;
        _isliked = false;
        widget.likes[widget.currentUser] = false;
      });
    } else {
      FirebaseFirestore.instance
          .collection("posts")
          .doc(ownerId)
          .collection("usersPosts")
          .doc(postId)
          .update({'likes.$currentUser': true});
      addLikeToActivity();

      setState(() {
        likecount += 1;
        _isliked = true;
        widget.likes[widget.currentUser] = true;
      });
    }
  }

  bildpostimage() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            handllikepost(); // معالجة ضغط على الصورة
          },
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: CachedNetworkImage(
              imageUrl: widget.mediaUrl,
              fit: BoxFit.cover,
              height: 350,
              width: MediaQuery.of(context).size.width,
              placeholder: (context, url) =>
                  Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
        if (widget.description.isNotEmpty)
          Positioned(
            bottom: 15,
            right: 10, // محاذاة النص لليمين
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showCaption = true; // إظهار النص عند الضغط
                  });
                },
                child: showCaption
                    ? Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14, // حجم الخط أصغر بقليل
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right, // محاذاة النص لليمين
                      )
                    : Text(
                        'Caption', // النص الذي يظهر قبل الضغط
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14, // حجم الخط أصغر بقليل
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right, // محاذاة النص لليمين
                      ),
              ),
            ),
          ),
        Positioned(
          child: bildpostheadr(), // عرض الهيدر
        ),
      ],
    );
  }

  bildpostFooter() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 224, 220, 185), // استخدام لون أبيض ناعم
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15.0),
              bottomRight: Radius.circular(15.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  handllikepost();
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      _isliked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: _isliked ? Colors.red : Colors.grey,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '$likecount Likes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showcomment(context,
                      postId: postId, ownerId: ownerId, mediaUrl: mediaUrl);
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.comment_bank_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 5),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('comments')
                          .doc(postId)
                          .collection('comments')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            '0 Comments',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        int commentCount = snapshot.data!.docs.length;
                        return Text(
                          '$commentCount Comments',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  Share.share(
                    'اكتب هنا النص الذي تريد مشاركته',
                    subject: 'عنوان المشاركة هنا',
                    sharePositionOrigin:
                        box.localToGlobal(Offset.zero) & box.size,
                  );
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.share,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // وظيفة لحذف البوست
  void _deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(ownerId)
          .collection("usersPosts")
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (error) {
      print('Error deleting post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post')),
      );
    }
  }

  // وظيفة لعرض نافذة الحذف
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deletePost();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          bildpostimage(),
          bildpostFooter(),
          // إظهار الأيقونة فقط للمالك
        ],
      ),
    );
  }
}

showcomment(context,
    {required String postId,
    required String ownerId,
    required String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return comments(postId: postId, ownerId: ownerId, mediaUrl: mediaUrl);
  }));
}
