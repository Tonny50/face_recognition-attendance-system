import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

final FirebaseStorage _storage = FirebaseStorage.instance;

Future<String> uploadImage(File imageFile) async {
  try {
    final reference = _storage.ref().child('photos/${DateTime.now().toString()}');
    final uploadTask = reference.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('Error uploading image: $e');
    return '';
  }
}
