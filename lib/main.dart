import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ig_mate/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold());
  }
}

//! always use dotenv and ignore the secrets before push
// tell i get a notebook

// firebase login
// flutterfire configure
// add the options file to gitignore
// come to main.dart and initialize firebase
// for auth feature 
// flutter pub add firebase_auth
