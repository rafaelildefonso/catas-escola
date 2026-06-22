import 'package:flutter/foundation.dart';

Future<void> renderPage(String path) async {
  debugPrint('renderPage called on non-web platform: $path');
}

void navigateTo(String path) {
  debugPrint('navigateTo called on non-web platform: $path');
}
