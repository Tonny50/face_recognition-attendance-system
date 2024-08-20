import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'face_recognition_service.dart';  // Import the service here

class FaceRecognitionPage extends StatefulWidget {
  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _cameraController;
  late Future<void> _initializeControllerFuture;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: false,
      enableClassification: true,
    ),
  );
  bool _isDetecting = false;
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted) {
      try {
        final cameras = await availableCameras();
        final firstCamera = cameras.first;

        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.high,
        );

        await _cameraController!.initialize();
        _scanForFaces();
      } catch (e) {
        print("Camera initialization error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera initialization error: $e")),
        );
      }
    } else {
      print("Camera permission not granted");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera permission not granted")),
      );
    }
  }

  void _scanForFaces() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final inputImage = InputImage.fromBytes(
          bytes: concatenatePlanes(image.planes),
          metadata: buildMetaData(image),
        );

        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          print("Face detected!");

          // Extract face features using FaceRecognitionService
          final Uint8List faceImage = _extractFaceImage(image, faces.first);
          final features = await _faceRecognitionService.extractFaceFeatures(faceImage);

          final recognizedUserId = await _faceRecognitionService.recognizeUser(features);
          if (recognizedUserId != null) {
            print('Recognized user: $recognizedUserId');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recognized user: $recognizedUserId')),
            );
          } else {
            print('User not recognized');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User not recognized')),
            );
          }
        }
      } catch (e) {
        print("Error detecting faces: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error detecting faces: $e")),
        );
      } finally {
        _isDetecting = false;
      }
    });
  }

  Uint8List _extractFaceImage(CameraImage image, Face face) {
    final bytes = concatenatePlanes(image.planes);
    final img.Image? originalImage = img.decodeImage(Uint8List.fromList(bytes));

    if (originalImage == null) {
      throw Exception("Failed to decode the image");
    }

    // Ensure that faceRect properties are integers
      final faceImage = img.copyCrop(
  originalImage,                 // The source image to be cropped
  x: face.boundingBox.left.toInt(), // The X coordinate of the top-left corner
  y: face.boundingBox.top.toInt(),  // The Y coordinate of the top-left corner
  width: face.boundingBox.width.toInt(), // The width of the cropped area
  height: face.boundingBox.height.toInt(), // The height of the cropped area
 );

    // Resize the cropped face to 112x112 (or any size expected by your model)
    final resizedFace = img.copyResize(faceImage, width: 112, height: 112);

    return Uint8List.fromList(img.encodeJpg(resizedFace));
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Recognition Attendance System'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, '/registration'); // Navigate to Registration Page
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_cameraController == null || !_cameraController!.value.isInitialized) {
              return Center(child: Text('Camera not initialized'));
            }
            return CameraPreview(_cameraController!);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanForFaces,
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final List<int> allBytes = [];
    for (final Plane plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  InputImageMetadata buildMetaData(CameraImage image) {
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final imageRotation = InputImageRotationValue.fromRawValue(
      _cameraController!.description.sensorOrientation,
    ) ?? InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormatValue.fromRawValue(
      image.format.raw,
    ) ?? InputImageFormat.nv21;

    return InputImageMetadata(
      size: size,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );
  }
}
