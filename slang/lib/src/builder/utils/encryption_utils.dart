extension StringEncryptionExt on String {
  /// Encrypts the string using the provided secret.
  List<int> encrypt(int secret) {
    final chars = [...codeUnits];
    for (var i = 0; i < chars.length; i++) {
      chars[i] = chars[i] ^ secret;
    }
    return chars;
  }
}

List<int> getParts0(int secret) {
  int b = secret % 17;
  int a = secret % 5;
  int c = secret ^ (a + b * 2);
  return [a, b, c];
}

List<int> getParts1(int secret) {
  int b = secret % 7;
  int a = secret % 21;
  int c = secret ^ (a * a - b);
  return [a, b, c];
}
