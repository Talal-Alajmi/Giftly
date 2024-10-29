import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:giftle/auth.dart';
import 'package:giftle/model/profile.dart';
import 'package:giftle/wegedt/progreas.dart';

final ratingsRef = FirebaseFirestore.instance.collection("ratings");
String currentUserId = FirebaseAuth.instance.currentUser!.uid;

class RatedUsersPage extends StatefulWidget {
  @override
  _RatedUsersPageState createState() => _RatedUsersPageState();
}

class _RatedUsersPageState extends State<RatedUsersPage> {
  final List<String> categories = [
    'Flowers',
    'Perfumes',
    'Beads',
    'Watches',
    'Beauty',
    'Dresses',
    'Jewelry',
    'Electronic'
  ];

  // دالة الانتقال إلى صفحة البروفايل
  void shoProfil(BuildContext context, String userIdadd) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Profile(profilid: userIdadd);
    }));
  }

  Future<double> calculateAverageRating(String userId) async {
    QuerySnapshot snapshot =
        await ratingsRef.doc(userId).collection('userRatings').get();

    if (snapshot.docs.isEmpty) {
      return 0.0; // إذا لم يكن هناك أي تقييمات
    }

    double totalRating = 0;
    snapshot.docs.forEach((doc) {
      totalRating += doc['rating'];
    });

    return totalRating / snapshot.docs.length; // حساب المتوسط
  }

  Widget buildRatedUsers() {
    return StreamBuilder(
      stream: usersRef.where('rating', isGreaterThanOrEqualTo: 0).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;

        // تقسيم المستخدمين حسب الفئات
        Map<String, List<DocumentSnapshot>> categorizedUsers = {};
        for (var category in categories) {
          categorizedUsers[category] =
              users.where((user) => user['category'] == category).toList();
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            String category = categories[index];
            List<DocumentSnapshot> usersInCategory =
                categorizedUsers[category] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  category,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                trailing: Icon(Icons.expand_more, color: Colors.black54),
                children: usersInCategory.isNotEmpty
                    ? usersInCategory.map((user) {
                        return FutureBuilder<double>(
                          future: calculateAverageRating(
                              user.id), // حساب متوسط التقييم
                          builder: (context, ratingSnapshot) {
                            if (!ratingSnapshot.hasData) {
                              return circularProgress();
                            }

                            double averageRating = ratingSnapshot.data ?? 0.0;

                            return FutureBuilder<DocumentSnapshot>(
                              future: usersRef.doc(user.id).get(),
                              builder: (context, bioSnapshot) {
                                if (!bioSnapshot.hasData) {
                                  return circularProgress();
                                }

                                var bioData = bioSnapshot.data?.data()
                                    as Map<String, dynamic>;
                                String bio =
                                    bioData['bio'] ?? 'No bio available';

                                return Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  padding: EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(248, 243, 236,
                                        199), // نفس لون الـ AppBar
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => shoProfil(context,
                                                user.id), // عند الضغط على الصورة
                                            child: CircleAvatar(
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                      user['photoUrl']),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => shoProfil(
                                                      context,
                                                      user.id), // عند الضغط على الاسم
                                                  child: Text(
                                                    user['name'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  bio,
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    RatingBarIndicator(
                                                      rating: averageRating,
                                                      itemBuilder:
                                                          (context, index) =>
                                                              Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                      direction:
                                                          Axis.horizontal,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      averageRating
                                                          .toStringAsFixed(
                                                              1), // عرض المتوسط
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      FutureBuilder<DocumentSnapshot>(
                                        future: ratingsRef
                                            .doc(user.id)
                                            .collection('userRatings')
                                            .doc(currentUserId)
                                            .get(),
                                        builder: (context, ratingSnapshot) {
                                          if (!ratingSnapshot.hasData) {
                                            return circularProgress();
                                          }

                                          bool hasRated =
                                              ratingSnapshot.data?.exists ??
                                                  false;

                                          return hasRated
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'You have already rated this user',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      showRatingDialog(user);
                                                    },
                                                    child:
                                                        Text('Rate this user'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.amber,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }).toList()
                    : [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No accounts available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
              ),
            );
          },
        );
      },
    );
  }

  void showRatingDialog(DocumentSnapshot user) {
    double selectedRating = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate ${user['name']}'),
        content: RatingBar.builder(
          initialRating: selectedRating,
          minRating: 0,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            selectedRating = rating;
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () {
              saveRating(user, selectedRating);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void saveRating(DocumentSnapshot user, double rating) {
    // تحديث التقييم في قاعدة البيانات
    usersRef.doc(user.id).update({
      'rating': rating,
    });

    // حفظ التقييم في سجل التقييمات
    ratingsRef.doc(user.id).collection('userRatings').doc(currentUserId).set({
      'rating': rating,
      'userId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Center(
          child: Text(
            'Rated Users',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildRatedUsers(),
      ),
    );
  }
}
