import 'package:cloud_firestore/cloud_firestore.dart';

class Usser {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;

  Usser(
      {required this.id,
      required this.name,
      required this.email,
      required this.photoUrl,
      required this.displayName,
      required this.bio});

  factory Usser.fromDocument(DocumentSnapshot doc) {
    return Usser(
        id: doc["id"],
        name: doc["name"],
        email: doc["email"],
        photoUrl: doc["photoUrl"],
        displayName: doc["displayname"],
        bio: doc["bio"]);
  }
}
