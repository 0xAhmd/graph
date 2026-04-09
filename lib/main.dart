import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ig_mate/layout/blocked.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'injection_container.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Security checks
  final isJailBroken = await JailbreakRootDetection.instance.isJailBroken;
  final isRealDevice = await JailbreakRootDetection.instance.isRealDevice;

  final isUnsafe = isJailBroken || !isRealDevice;

  if (!isUnsafe) {
    runApp(const BlockedDeviceApp());
    return;
  }

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase URL or Anon Key is missing in .env file');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  runApp(const MyApp());
}
