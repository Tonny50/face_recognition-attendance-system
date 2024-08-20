import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;
  //final List<int> _inputShape = [1, 112, 112, 3]; // The model's expected input shape
  final List<int> _outputShape = [1, 192]; // The model's output shape

  FaceRecognitionService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<double>> extractFaceFeatures(Uint8List inputImage) async {
    var input = inputImage.buffer.asUint8List();
    var output = List.filled(_outputShape.reduce((a, b) => a * b), 0.0).reshape(_outputShape);

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  bool compareFaceFeatures(List<double> newFeatures, List<double> storedFeatures, {double threshold = 0.6}) {
    double distance = _calculateEuclideanDistance(newFeatures, storedFeatures);
    return distance < threshold;
  }

  double _calculateEuclideanDistance(List<double> vector1, List<double> vector2) {
    double sum = 0.0;
    for (int i = 0; i < vector1.length; i++) {
      sum += pow((vector1[i] - vector2[i]), 2);
    }
    return sqrt(sum);
  }

  // Define the recognizeUser method
  Future<String?> recognizeUser(List<double> newFeatures) async {
    final CollectionReference users = FirebaseFirestore.instance.collection('users');

    // Fetch all users from Firestore
    final QuerySnapshot snapshot = await users.get();

    // Iterate over each user and compare face features
    for (final DocumentSnapshot doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final List<dynamic> storedFeatures = data['features'];

      if (storedFeatures.isNotEmpty) {
        final List<double> storedFeaturesList = List<double>.from(storedFeatures);

        // Compare new features with stored features
        if (compareFaceFeatures(newFeatures, storedFeaturesList)) {
          // If a match is found, return the user ID
          return doc.id;
        }
      }
    }

    // Return null if no match is found
    return null;
  }
}
