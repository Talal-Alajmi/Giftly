import 'package:cloud_firestore/cloud_firestore.dart';

// هذي صفحة جلب البيانات

class UserDataService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await _userCollection.doc(userId).get();
      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception('User not found!');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }
}
