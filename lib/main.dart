import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ig_mate/app.dart';

import 'package:ig_mate/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  final supabaseUrl = dotenv.env['url'];
  final supabaseAnonKey = dotenv.env['anonKey'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase URL or Anon Key is missing in .env file');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

// add the firebase_auth import in main.dart
// check WidgetsFlutterBinding.ensureInitialized();
// call await Firebase.initializeApp();
// wrap MaterialApp with StreamBuilder for auth state
// show login/signup screen if user is null
// show home screen if user is logged in
// create auth service to handle sign in, sign out, register
// use FirebaseAuth.instance for auth actions
// validate user input in login/signup forms
// display error messages with SnackBar or similar
// add loading indicator during async calls
// navigate to home after successful login or registration
// enable email/password sign-in in Firebase Console
// configure project settings in Firebase Console properly
// handle email verification if needed
// optionally add Google sign-in or other providers
// update pubspec.yaml with required dependencies
// test on both Android and iOS emulators/devices
// use try-catch blocks for all async Firebase calls
// clean up controllers and listeners when disposing widgets
// style the auth screens for good UX
// show user email or name in the home screen
// consider adding logout button in an app bar or drawer
// optionally use Riverpod, BLoC, or Provider for state
// verify Firebase setup in `flutterfire configure` output
// use dotenv for storing API keys or secrets
// always gitignore `.env` and options files
// make sure Google Services files are in correct platforms
// review AndroidManifest.xml and Info.plist for config
// check Firebase projectId matches in all places
// configure Firebase rules for Firestore/Auth as needed
// optionally add user profiles with Firestore
// update app’s launch screen and icon for production
// keep auth flow smooth, avoid long loading times

//!todo make in profile page staggard list view
