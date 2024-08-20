import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart'; 
import 'face_recognition_service.dart'; // Import the FaceRecognitionService
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matricNumberController = TextEditingController();
  XFile? _photo;
  final ImagePicker _picker = ImagePicker();
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _photo = pickedFile;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Upload photo to Firebase Storage
        final photoUrl = await uploadImage(File(_photo!.path));

        // Extract face features from the photo
        final faceFeatures = await _extractFaceFeatures(File(_photo!.path));

        // Store data in Firestore
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text,
          'matric_number': _matricNumberController.text,
          'photo_url': photoUrl,
          'face_features': faceFeatures, // Store face features
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration successful!')));
      } catch (e) {
        print('Error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed')));
      }
    }
  }

  Future<List<double>> _extractFaceFeatures(File imageFile) async {
    // Convert image file to Uint8List and extract features
    final inputImage = await _convertToUint8List(imageFile);
    return await _faceRecognitionService.extractFaceFeatures(inputImage);
  }

  Future<Uint8List> _convertToUint8List(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw Exception("Unable to decode image");
    }

    // Resize the image to match the model input size (112x112)
    final resizedImage = img.copyResize(image, width: 112, height: 112);

    // Convert the image to a Uint8List as needed by TensorFlow Lite
    return Uint8List.fromList(resizedImage.getBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _matricNumberController,
                decoration: InputDecoration(labelText: 'Matriculation Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your matriculation number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _photo == null
                  ? Text('No image selected.')
                  : Image.file(File(_photo!.path)),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Take Photo'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
