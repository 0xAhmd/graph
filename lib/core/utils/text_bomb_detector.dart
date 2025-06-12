bool isTextBomb(String message) {
  if (message.length > 5000) return true;

  if (RegExp(r'\n').allMatches(message).length > 100) return true;

  if (RegExp(r'(.)\1{299,}').hasMatch(message)) return true;

  if (RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true).allMatches(message).length > 1000) {
    return true;
  }

  return false;
}



