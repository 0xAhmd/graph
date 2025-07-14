//cspell:disable
import 'dart:io';

import 'package:ig_mate/index.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class BlockedDeviceApp extends StatelessWidget {
  const BlockedDeviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlockedDeviceScreen(),
    );
  }
}

class BlockedDeviceScreen extends StatefulWidget {
  const BlockedDeviceScreen({super.key});

  @override
  State<BlockedDeviceScreen> createState() => _BlockedDeviceScreenState();
}

class _BlockedDeviceScreenState extends State<BlockedDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Show the alert after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBlockedAlert(context);
    });
  }

  void _showBlockedAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Blocked Device',
      text:
          'Your device is jailbroken or rooted.\nThis app cannot run on unsafe devices.',
      barrierDismissible: false,
      confirmBtnText: 'Exit',
      confirmBtnColor: Colors.redAccent,
      showCancelBtn: false,
      onConfirmBtnTap: () {
        exit(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Black background behind the alert
    return const Scaffold(backgroundColor: Colors.black);
  }
}
