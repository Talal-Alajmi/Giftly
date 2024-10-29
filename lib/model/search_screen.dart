import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/model/profile.dart';

final FirebaseFirestore userRef = FirebaseFirestore.instance;

class SearchUserPage extends StatefulWidget {
  final String currentUserID; // Add currentUserID parameter

  const SearchUserPage({Key? key, required this.currentUserID})
      : super(key: key);

  @override
  _SearchUserPageState createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  String searchQuery = '';
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false; // Add isLoading state

  // Function to search users
  Future<void> searchUser() async {
    if (searchQuery.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true; // Set isLoading to true when searching
    });

    // Query Firestore collection for users
    final QuerySnapshot userSnapshot = await userRef.collection('users').get();

    // Filter users based on search query
    final List<Map<String, dynamic>> filteredUsers = userSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((user) => user['name']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    setState(() {
      searchResults = filteredUsers;
      isLoading = false; // Set isLoading to false when search completes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/47.jpg'),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 25,
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    if (searchQuery.isEmpty) {
                      searchResults.clear();
                    } else {
                      searchUser();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  filled: true,
                  fillColor: Colors.grey[250], // لون رصاصي
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                  // تعيين حواف مستديرة لمربع البحث
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  // تغيير حجم المربع
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              ),
            ),
            if (isLoading) // Show loading indicator when searching
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> userData = searchResults[index];
                  final String userID =
                      userData['id']; // Assuming 'id' is the key for user ID

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData['photoUrl'] ??
                          'https://th3developer.files.wordpress.com/2014/01/4fb0c-facebook-profile-image.jpg'),
                    ),
                    title: Row(
                      children: [
                        Text(userData['name']),
                        const SizedBox(width: 10),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Profile(
                                  profilid: userID,
                                )),
                      );
                    },
                  );
                },
              ),
            ),
            if (searchQuery.isNotEmpty && searchResults.isEmpty && !isLoading)
              Center(
                child: Text(
                  'No information available',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final int count;
  final String label;

  const ProfileStat({
    Key? key,
    required this.count,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}























// class UserProfilePage extends StatelessWidget {
//   final Map<String, dynamic> userData;
//   final bool isCurrentUser; // Add isCurrentUser flag

//   const UserProfilePage({
//     Key? key,
//     required this.userData,
//     required this.isCurrentUser,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Profile: ${userData['name']}'),
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('images/decor.png'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundImage: CachedNetworkImageProvider(userData[
//                               'photoUrl'] ??
//                           'https://th3developer.files.wordpress.com/2014/01/4fb0c-facebook-profile-image.jpg'),
//                     ),
//                     const SizedBox(width: 5),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           userData['name'],
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Row(
//                           children: [
//                             ProfileStat(count: 100, label: 'Followers'),
//                             const SizedBox(width: 15),
//                             ProfileStat(count: 50, label: 'Following'),
//                             const SizedBox(width: 15),
//                             ProfileStat(count: 20, label: 'Posts'),
//                             if (!isCurrentUser) // Show follow button if not current user
//                               ElevatedButton(
//                                 onPressed: () {
//                                   // Add functionality for follow button
//                                 },
//                                 child: const Text('متابعة'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   textStyle: const TextStyle(fontSize: 20),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 5,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         Text(
//                           userData['bio'],
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Expanded(
//                 child: GridView.builder(
//                   padding: const EdgeInsets.all(10),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     mainAxisSpacing: 10,
//                     crossAxisSpacing: 10,
//                   ),
//                   itemCount: 10, // Number of posts
//                   itemBuilder: (context, index) {
//                     return Container(
//                       color: Colors.grey[200],
//                       child: Center(
//                         child: Text('Post $index'),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
