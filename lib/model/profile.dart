import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/pages/Flowersgpage.dart';
import 'package:giftle/pages/Myevint.dart';
import 'package:giftle/pages/Mywish.dart';
import 'package:giftle/pages/followingpage.dart';
import 'package:giftle/wegedt/navbar.dart';
import 'package:giftle/wegedt/post_title.dart';
import 'package:giftle/wegedt/progreas.dart';
import '../pages/pagepost.dart';

class Profile extends StatefulWidget {
  final String profilid;
  Profile({required this.profilid});
  final user = FirebaseAuth.instance.currentUser;
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;
  String postView = "grid";
  bool isLoading = false;
  int _profilePostsCount = 0;
  List<Post> posts = [];
  bool isFllowing = false;
  int folloingcoun = 0;
  int folloerscoun = 0;
  int myWishCount = 0; // متغير لحفظ عدد My Wish

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIsFollowing();
    getMyWishCount();
  }

  // دالة لجلب عدد My Wish من قاعدة البيانات
  Future<void> getMyWishCount() async {
    try {
      // استرجاع مجموعة "My Wish" من Firebase حيث profilid يساوي profilid الحالي
      QuerySnapshot wishSnapshot = await FirebaseFirestore.instance
          .collection('Wishlist') // اسم المجموعة التي تحتوي على wish list
          .where('profilid', isEqualTo: widget.profilid) // البحث عن profilid
          .get();

      // تحديث حالة myWishCount بعد الحصول على البيانات
      setState(() {
        myWishCount = wishSnapshot.docs.length; // عدد الوثائق المتطابقة
      });
    } catch (error) {
      print('Error fetching My Wish count: $error');
    }
  }

  Future<void> getFollowers() async {
    {
      // الوصول إلى مجموعة 'userfolloers' الخاصة بالمستخدم
      CollectionReference userFollowersRef =
          followersRef.doc(widget.profilid).collection('userfolloers');

      // جلب الوثائق داخل المجموعة
      QuerySnapshot querySnapshot = await userFollowersRef.get();
      List<DocumentSnapshot> documents = querySnapshot.docs;

      // تحديث حالة المتغير followingCount
      setState(() {
        folloerscoun = documents.length;
      });
    }
  }

  Future<void> getFollowing() async {
    {
      // الوصول إلى مجموعة 'userfolloers' الخاصة بالمستخدم
      CollectionReference userFollowersRef =
          followeingRef.doc(widget.profilid).collection('userfolloers');

      // جلب الوثائق داخل المجموعة
      QuerySnapshot querySnapshot = await userFollowersRef.get();
      List<DocumentSnapshot> documents = querySnapshot.docs;

      // تحديث حالة المتغير followingCount
      setState(() {
        folloingcoun = documents.length;
      });
    }
  }

  checkIsFollowing() async {
    DocumentSnapshot doc = await followeingRef
        .doc(currentUser)
        .collection('userfolloers')
        .doc(widget.profilid)
        .get();
    setState(() {
      isFllowing = doc.exists;
    });
  }

  Widget BuildCount(BuildContext context, String name, String count) {
    return GestureDetector(
      onTap: () {
        if (name == 'Following') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  showfolloing(context, profilid: widget.profilid),
            ),
          );
        } else if (name == 'Followers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  showfolloers(context, profilid: widget.profilid),
            ),
          );
        } else if (name == 'Posts') {
          // يمكنك إضافة التنقل إلى شاشة عرض المنشورات هنا
        }
      },
      child: Column(
        children: <Widget>[
          Text(
            count,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          Text(
            name,
            style: TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  evintProfileButton(
    context, {
    required String profilid,
  }) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return MyEvint(profilid: profilid);
    }));
  }

  mywishProfileButton(
    context, {
    required String profilid,
  }) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Wish(
        profilid: profilid,
      );
    }));
  }

  handleUnfollowinguser() {
    setState(() {
      isFllowing = false;
    });
    followersRef
        .doc(widget.profilid)
        .collection('userfolloers')
        .doc(currentUser)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    followeingRef
        .doc(currentUser)
        .collection('userfolloers')
        .doc(widget.profilid)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    feedsRef
        .doc(widget.profilid)
        .collection('feeditem')
        .doc(currentUser)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowinguser() async {
    setState(() {
      isFllowing = true;
    });

    DocumentSnapshot snapshott = await usersRef.doc(currentUser).get();
    var userDataa = snapshott.data() as Map<String, dynamic>;
    var userPhotoUrlc = userDataa['photoUrl'];
    var usernamec = userDataa['name'];
    followersRef
        .doc(widget.profilid)
        .collection('userfolloers')
        .doc(currentUser)
        .set({
      'username': usernamec,
      'timestamp': DateTime.now(),
      'userId': currentUser,
      'avataFotourl': userPhotoUrlc
    });
    DocumentSnapshot snapshotp = await usersRef.doc(widget.profilid).get();
    var userpData = snapshotp.data() as Map<String, dynamic>;
    var userPhotoUrlp = userpData['photoUrl'];
    var usernamep = userpData['name'];

    followeingRef
        .doc(currentUser)
        .collection('userfolloers')
        .doc(widget.profilid)
        .set({
      'username': usernamep,
      'timestamp': DateTime.now(),
      'userId': widget.profilid,
      'avataFotourl': userPhotoUrlp
    });

    DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

    // استخراج معلومات المستخدم
    var userData = snapshot.data() as Map<String, dynamic>;
    var userPhotoUrl = userData['photoUrl'];
    var username = userData['name'];

    // تحديث مجموعة البيانات في Firestore
    {
      await feedsRef
          .doc(widget.profilid)
          .collection('feeditem')
          .doc(currentUser)
          .set({
        'type': 'Follow',
        'username': username,
        'userId': widget.profilid,
        'userprofimf': userPhotoUrl,
        'timestamp': Timestamp.now(),
        'commentdata': '',
        'userIdadd': currentUser,
        'isRead': false
      });
    }
  }

  BuildProfileButton() {
    bool isProfileoner = currentUser == widget.profilid;
    if (isProfileoner) {
      return Container();
    } else if (isFllowing) {
      return BuildButton(text: 'UnFollowing', function: handleUnfollowinguser);
    } else if (!isFllowing) {
      return BuildButton(text: 'Following', function: handleFollowinguser);
    }
  }

  BuildButton({required String text, required function}) {
    return Container(
      padding: EdgeInsets.only(left: 5),
      child: TextButton(
        onPressed: () => function(),
        child: Row(
          children: [
            Container(
              width: 140.0,
              height: 30.0,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(color: Colors.white),
              ),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(5.0)),
            ),
          ],
        ),
      ),
    );
  }

  BuildProfileHeader() {
    return FutureBuilder(
        future: usersRef.doc(widget.profilid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userPhotoUrl = userData['photoUrl'] ??
              'https://th3developer.files.wordpress.com/2014/01/4fb0c-facebook-profile-image.jpg';
          final username = userData['displayname'] ?? '';
          final userbio = userData['bio'] ?? '';
          return Container(
            color: Color.fromARGB(248, 243, 239, 220),
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(userPhotoUrl),
                      radius: 40.0,
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              BuildCount(context, "Posts",
                                  _profilePostsCount.toString()),
                              GestureDetector(
                                  onTap: () => showfolloers(context,
                                      profilid: widget.profilid),
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        '$folloerscoun',
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Followers',
                                        style: TextStyle(
                                            fontSize: 16.0, color: Colors.grey),
                                      ),
                                    ],
                                  )),
                              GestureDetector(
                                  onTap: () => showfolloing(context,
                                      profilid: widget.profilid),
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        '$folloingcoun',
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Following',
                                        style: TextStyle(
                                            fontSize: 16.0, color: Colors.grey),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(top: 10.0),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    username,
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 10.0),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    userbio,
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                      color: Colors.grey,
                      shadows: [
                        Shadow(
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    BuildProfileButton(),
                    Container(
                      child: TextButton(
                        onPressed: () => mywishProfileButton(context,
                            profilid: widget.profilid),
                        child: Row(
                          children: [
                            Container(
                              width: 140.0,
                              height: 30.0,
                              alignment: Alignment.center,
                              child: Text(
                                'My Wish ($myWishCount)',
                                style: TextStyle(color: Colors.white),
                              ),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(5.0)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    widget.profilid == currentUser
                        ? Container(
                            child: TextButton(
                              onPressed: () => evintProfileButton(context,
                                  profilid: widget.profilid),
                              child: Row(
                                children: [
                                  Container(
                                    width: 140.0,
                                    height: 30.0,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'My Evint ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(5.0)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container()
                  ],
                )
              ],
            ),
          );
        });
  }

  Future<void> getProfilePosts() async {
    try {
      final postsSnapshot = await postsRef
          .doc(widget.profilid)
          .collection("usersPosts")
          .orderBy("timestamp", descending: true)
          .get();

      if (postsSnapshot.docs.isNotEmpty) {
        setState(() {
          posts =
              postsSnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
          _profilePostsCount = posts.length; // تحديث عدد المنشورات
        });
      } else {
        print('لا توجد منشورات لعرضها');
      }
    } catch (error) {
      print('حدث خطأ أثناء جلب المنشورات: $error');
    }
  }

  BuildToggleViewPost() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(
              Icons.grid_on,
              color: postView == "grid"
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () {
              setBuildTogglePost("grid");
            }),
        IconButton(
            icon: Icon(
              Icons.list,
              color: postView == "list"
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () {
              setBuildTogglePost("list");
            }),
      ],
    );
  }

  setBuildTogglePost(String view) {
    setState(() {
      postView = view;
    });
  }

  detBuildTogglePost(String view, Post post) {
    setState(() {
      postView = view;
    });
  }

  BuildPostProfile() {
    if (isLoading) {
      return circularProgress();
    } else if (postView == 'grid') {
      List<GridTile> gridTile = [];
      posts.forEach((post) {
        gridTile.add(GridTile(
            child: PostTile(
          post: post,
          onTapCallback: () {
            detBuildTogglePost("list", post);
          },
        )));
      });
      return GridView.count(
        padding: EdgeInsets.all(0),
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 1,
        shrinkWrap: true,
        children: gridTile,
        physics: NeverScrollableScrollPhysics(),
      );
    } else if (postView == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(248, 243, 239, 220),
        key: _scaffoldKey, // تعيين الـ GlobalKey هنا
        appBar: AppBar(
          backgroundColor: Color.fromARGB(248, 243, 239, 220),
          actions: [
            widget.profilid == currentUser
                ? IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  )
                : Container(),
          ],
        ),
        endDrawer: NavBar(),
        body: ListView(
          children: <Widget>[
            BuildProfileHeader(),
            BuildToggleViewPost(),
            BuildPostProfile(),
          ],
        ));
  }
}

showfolloing(
  context, {
  required String profilid,
}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Floingpage(profilid: profilid);
  }));
}

showfolloers(
  context, {
  required String profilid,
}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Flowersgpage(profilid: profilid);
  }));
}
