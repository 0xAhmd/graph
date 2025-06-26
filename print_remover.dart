import 'dart:io';

void main() async {
  final dir = Directory('./lib');
  await for (final file in dir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = await file.readAsString();

      // Remove all lines containing debugPrint(
      final updated = content.replaceAllMapped(
        RegExp(r'^\s*debugPrint\(.*\);\s*$', multiLine: true),
        (match) => '',
      );

      if (content != updated) {
        await file.writeAsString(updated);
      }
    }
  }
}
