import 'dart:io';

import 'package:flutter/cupertino.dart';

void main() async {
  final dir = Directory('./lib');
  await for (final file in dir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = await file.readAsString();

      // Replace print( with debugPrint(
      final updated = content.replaceAllMapped(
        RegExp(r'(^|\s)print\('),
        (match) => '${match.group(1)}debugPrint(',
      );

      if (content != updated) {
        await file.writeAsString(updated);
        debugPrint('Updated: ${file.path}');
      }
    }
  }
  debugPrint('All print statements replaced with debugPrint.');
}