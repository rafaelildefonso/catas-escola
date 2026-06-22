import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<void> renderPage(String path) async {
  try {
    final request = await html.HttpRequest.request(path);
    final content = request.responseText;
    if (content != null) {
      js.context['_renderPageContent'] = content;
      js.context.callMethod('eval', [
        'document.open(); document.write(_renderPageContent); document.close(); delete window._renderPageContent;'
      ]);
    }
  } catch (e) {
    debugPrint('Failed to fetch $path: $e');
  }
}

void navigateTo(String path) {
  html.window.location.href = path;
}
