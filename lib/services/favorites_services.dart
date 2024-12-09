import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addToFavorites(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.set({
      "favorites": FieldValue.arrayUnion([itemId])
    }, SetOptions(merge: true));
  }

  Future<void> removeFromFavorites(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.update({
      "favorites": FieldValue.arrayRemove([itemId])
    });
  }

  Future<List<String>> getFavorites() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      return List<String>.from(data?['favorites'] ?? []);
    }

    return [];
  }
}
