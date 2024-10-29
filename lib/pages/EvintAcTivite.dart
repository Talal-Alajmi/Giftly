import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class EvintAcTivite extends StatefulWidget {
  final String EvindID;
  final String userIdadd;

  EvintAcTivite({required this.EvindID, required this.userIdadd});

  @override
  _EvintAcTiviteState createState() => _EvintAcTiviteState();
}

class _EvintAcTiviteState extends State<EvintAcTivite> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController messageController = TextEditingController();
  Future<DocumentSnapshot> _fetchEventDetails() async {
    try {
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.EvindID)
          .get();
      return eventSnapshot;
    } catch (e) {
      print("Error fetching event details: $e");
      rethrow;
    }
  }

  Map<String, bool> selectedGifts = {};

  void _acceptInvitation() async {
    final currentUser = FirebaseAuth.instance.currentUser?.uid;

    // Check if message field is not empty

    if (messageController.text.trim().isNotEmpty) {
      // Fetch user information
      DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

      var userData = snapshot.data() as Map<String, dynamic>;
      var username = userData['name'];
      var userImage = userData['photoUrl']; // Assuming you have image_url field

      // Add message to event messages
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.EvindID)
          .collection('messages')
          .doc()
          .set({
        'message': messageController.text.trim(),
        'sender': currentUser,
        'senderName': username,
        'senderImage': userImage,
        'timestamp': Timestamp.now(),
      });
    }

    // Update gifts status
    for (var giftId in selectedGifts.keys) {
      if (selectedGifts[giftId] == true) {
        DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

        // Get user information
        var userData = snapshot.data() as Map<String, dynamic>;

        var username = userData['name'];
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.EvindID)
            .collection('gifts')
            .doc(giftId)
            .update({'Sponsored': '$username', 'status': 'yescom'});
      }
    }

    // Update user status to attending
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.EvindID)
        .collection('attendees')
        .doc(currentUser)
        .update({'status': 'attending'});

    // Navigate back
    Navigator.pop(context);
  }

  void _declineInvitation() async {
    final currentUser = FirebaseAuth.instance.currentUser?.uid;

    // Check if message field is not empty

    if (messageController.text.trim().isNotEmpty) {
      // Fetch user information
      DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

      var userData = snapshot.data() as Map<String, dynamic>;
      var username = userData['name'];
      var userImage = userData['photoUrl']; // Assuming you have image_url field

      // Add message to event messages
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.EvindID)
          .collection('messages')
          .doc()
          .set({
        'message': messageController.text.trim(),
        'sender': currentUser,
        'senderName': username,
        'senderImage': userImage,
        'timestamp': Timestamp.now(),
      });
    }

    // Update gifts status
    for (var giftId in selectedGifts.keys) {
      if (selectedGifts[giftId] == true) {
        DocumentSnapshot snapshot = await usersRef.doc(currentUser).get();

        // Get user information
        var userData = snapshot.data() as Map<String, dynamic>;

        var username = userData['name'];
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.EvindID)
            .collection('gifts')
            .doc(giftId)
            .update({'Sponsored': '$username', 'status': 'yescom'});
      }
    }

    // Update user status to attending
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.EvindID)
        .collection('attendees')
        .doc(currentUser)
        .update({'status': 'declined'});

    // Navigate back
    Navigator.pop(context);
  }

  void _openMap(String? locationUrl) async {
    if (locationUrl != null && await canLaunch(locationUrl)) {
      await launch(locationUrl);
    } else {
      throw 'Could not launch $locationUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Event Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchEventDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading event details.'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No event details available.'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var eventName = data['name'];
          var eventDate = (data['date'] as Timestamp?)?.toDate();
          var eventTime = (data['date'] as Timestamp?)?.toDate();
          var eventLocationUrl = data['locationUrl'];
          var eventcity = data['city'];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Name: $eventName',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${eventDate != null ? DateFormat('yyyy-MM-dd').format(eventDate) : 'Not Available'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time: ${eventTime != null ? DateFormat('HH:mm').format(eventTime) : 'Not Available'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => _openMap(eventLocationUrl),
                    child: Card(
                      shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('$eventcity',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Image.asset(
                              'images/5555.jpg', // Replace with your actual map image URL
                              height: 100,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Wish List',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('events')
                                .doc(widget.EvindID)
                                .collection('gifts')
                                .where('status', isEqualTo: 'nocom')
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Text(
                                    'No gifts found.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              }
                              var giftDocs = snapshot.data!.docs;
                              return Container(
                                height: 150,
                                child: ListView.builder(
                                  itemCount: giftDocs.length,
                                  itemBuilder: (context, index) {
                                    var gift = giftDocs[index];
                                    var giftId = gift.id;
                                    var giftData =
                                        gift.data() as Map<String, dynamic>;
                                    var giftName = giftData['name'];

                                    var giftImageUrl = giftData['image_url'];

                                    return ListTile(
                                      leading: giftImageUrl != null
                                          ? SizedBox(
                                              width: 40,
                                              height: 30,
                                              child: Image(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        giftImageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : null,
                                      title: Text(
                                        giftName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      trailing: Checkbox(
                                        value: selectedGifts[giftId] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedGifts[giftId] = value!;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              contentPadding: EdgeInsets.all(12),
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _acceptInvitation,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Accept',
                              style: TextStyle(color: Colors.white),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // To add spacing between buttons
                      Expanded(
                        child: TextButton(
                          onPressed: _declineInvitation,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Ignore',
                              style: TextStyle(color: Colors.white),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 206, 35, 23),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
