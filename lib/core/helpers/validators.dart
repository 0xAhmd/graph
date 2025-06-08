bool isValidEmail(String email) {
  final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return pattern.hasMatch(email);
}

bool hasDoubleSpaces(String input) {
  return RegExp(r'\s{2,}').hasMatch(input);
}

bool containsEmoji(String input) {
  final emojiPattern = RegExp(
    r'[\u203C-\u3299\uD83C\uD000-\uDFFF\uD83D\uD000-\uDFFF\uD83E\uD000-\uDFFF]',
  );
  return emojiPattern.hasMatch(input);
}

bool startsOrEndsWithSpace(String input) {
  return input != input.trim();
}
