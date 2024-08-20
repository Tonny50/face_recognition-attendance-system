import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Add user to Firestore
Future<void> addUser({
  required String name,
  required String matricNumber,
  required String photoUrl,
  required List<double> faceFeatures,
}) async {
  try {
    await _firestore.collection('users').add({
      'name': name,
      'matric_number': matricNumber,
      'photo_url': photoUrl,
      'face_features': faceFeatures,
    });
    print('User added successfully');
  } catch (e) {
    print('Error adding user: $e');
  }
}

// Fetch user by matriculation number
Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByMatricNumber(String matricNumber) async {
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('matric_number', isEqualTo: matricNumber)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  } catch (e) {
    print('Error fetching user: $e');
    return null;
  }
}

// Example to update a user's photo URL
Future<void> updateUserPhotoUrl(String documentId, String newPhotoUrl) async {
  try {
    await _firestore.collection('users').doc(documentId).update({
      'photo_url': newPhotoUrl,
    });
    print('User photo URL updated successfully');
  } catch (e) {
    print('Error updating photo URL: $e');
  }
}

// Example to delete a user
Future<void> deleteUser(String documentId) async {
  try {
    await _firestore.collection('users').doc(documentId).delete();
    print('User deleted successfully');
  } catch (e) {
    print('Error deleting user: $e');
  }
}
