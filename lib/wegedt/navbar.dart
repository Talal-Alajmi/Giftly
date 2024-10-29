import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giftle/model/editprofil.dart';
import 'package:giftle/model/user.dart';
import 'package:giftle/pages/supplier.dart';
import 'package:giftle/wegedt/progreas.dart';

class NavBar extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore userRef = FirebaseFirestore.instance;

  mywishProfileButton(
    context, {
    required String currentUser,
  }) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EditProfile(
        currentUserId: currentUser,
      );
    }));
  }

  NavBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      child: Drawer(
        backgroundColor: Color.fromARGB(248, 243, 239, 220),
        child: ListView(
          // Remove padding
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Container(
                width: MediaQuery.of(context).size.width,
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      userRef.collection('users').doc(user!.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return circularProgress();
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;

                    return Text(
                      userData['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              accountEmail: Text(user!.email!),
              currentAccountPicture: CircleAvatar(
                child: ClipOval(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        userRef.collection('users').doc(user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return circularProgress();
                      }
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final userPhotoUrl = userData['photoUrl'] ?? '';

                      return Center(
                        child: userPhotoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    CachedNetworkImageProvider(userPhotoUrl),
                                radius: 50,
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                      );
                    },
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.fill, image: AssetImage('images/profi.jpg')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Suppliers'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          RatedUsersPage()), // هنا ننتقل إلى صفحة الموردين
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Edit Profil'),
              onTap: () => mywishProfileButton(context, currentUser: user!.uid),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Policies'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              title: const Text('Exit'),
              leading: const Icon(Icons.exit_to_app),
              onTap: () {
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  // Replace 'user_id_here' with the actual user ID
  String userId = 'user_id_here';

  // Create an instance of UserDataService
  UserDataService userDataService = UserDataService();

  try {
    // Call getUserData to fetch user data
    Map<String, dynamic> userData = await userDataService.getUserData(userId);

    // Print the user data
    print('User ID: ${userData['id']}');
    print('Name: ${userData['name']}');
    print('Email: ${userData['email']}');
    print('Photo URL: ${userData['photoUrl']}');
    print('Bio: ${userData['bio']}');
    print('Timestamp: ${userData['timestamp']}');
  } catch (e) {
    print('Error: $e');
  }
}
