import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'face_recognition_page.dart';
import 'registration.dart'; 

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
  await Firebase.initializeApp(
    options: const FirebaseOptions( apiKey: "AIzaSyARep1ek9FHhKDqROsxzET7NoaNedotq4c",
       authDomain: "attendance-record-aa8fd.firebaseapp.com",
       projectId: "attendance-record-aa8fd",
       storageBucket: "attendance-record-aa8fd.appspot.com",
       messagingSenderId: "733207444868",
       appId: "1:733207444868:web:c119487186cc33b09371d1",
       measurementId: "G-PD7PR2XZE5")
    
  );}else{
     await Firebase.initializeApp();
  }

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FaceRecognitionPage(),
        '/registration': (context) => RegistrationPage(),
      },
    );
  }
}
