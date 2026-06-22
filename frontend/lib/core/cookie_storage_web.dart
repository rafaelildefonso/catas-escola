import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

/// Cookie-based session storage for Supabase on Flutter Web.
///
/// Replaces the default localStorage persistence with cookies. 
/// Because Supabase sessions can exceed the browser's 4KB cookie limit,
/// we chunk the session string into multiple cookies and base64 encode them.
class CookieSupabaseStorage extends LocalStorage {
  static const _cookieName = 'sb_session';

  const CookieSupabaseStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final value = _readCookie(_cookieName);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return _readCookie(_cookieName);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _setCookie(
      _cookieName,
      persistSessionString,
      maxAgeDays: 30,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    _deleteCookie(_cookieName);
  }

  // ---------------------------------------------------------------------------
  // Cookie helpers
  // ---------------------------------------------------------------------------

  /// Reads a cookie value (reassembling chunks if necessary).
  String? _readCookie(String name) {
    final cookies = web.document.cookie;
    if (cookies.isEmpty) return null;

    final pairs = cookies.split(';');
    final cookieMap = <String, String>{};
    for (final pair in pairs) {
      final eqIndex = pair.indexOf('=');
      if (eqIndex == -1) continue;
      final keyStr = pair.substring(0, eqIndex).trim();
      try {
        final key = Uri.decodeComponent(keyStr);
        final val = pair.substring(eqIndex + 1).trim();
        cookieMap[key] = val;
      } catch (_) {
        // ignore malformed cookies
      }
    }

    // Try reading chunked cookie
    if (cookieMap.containsKey('${name}_count')) {
      final count = int.tryParse(cookieMap['${name}_count']!) ?? 0;
      final buffer = StringBuffer();
      for (int i = 0; i < count; i++) {
        final chunk = cookieMap['${name}_$i'];
        if (chunk == null) return null; // Missing chunk, session is invalid
        buffer.write(chunk);
      }
      try {
        final decodedBytes = base64Decode(buffer.toString());
        return utf8.decode(decodedBytes);
      } catch (e) {
        return null;
      }
    }
    
    // Fallback for non-chunked or older cookies
    if (cookieMap.containsKey(name)) {
       try {
         final val = cookieMap[name]!;
         return Uri.decodeComponent(val);
       } catch (e) {
         return null;
       }
    }

    return null;
  }

  /// Sets a cookie, chunking it if it's too large, and applying Secure only on HTTPS.
  void _setCookie(String name, String value, {int maxAgeDays = 30}) {
    final bytes = utf8.encode(value);
    final encoded = base64Encode(bytes);
    final maxAge = maxAgeDays * 24 * 60 * 60; // seconds
    
    final isSecure = web.window.location.protocol == 'https:';
    final secureStr = isSecure ? '; Secure' : '';
    
    // Maximum cookie size is ~4000 bytes. We'll split the value into chunks of 3000 chars.
    const chunkSize = 3000;
    int chunkCount = (encoded.length / chunkSize).ceil();
    
    // Write chunk count
    web.document.cookie = '${Uri.encodeComponent(name)}_count=$chunkCount; path=/; max-age=$maxAge; SameSite=Lax$secureStr';
    
    for (int i = 0; i < chunkCount; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize < encoded.length ? (i + 1) * chunkSize : encoded.length;
      final chunk = encoded.substring(start, end);
      web.document.cookie = '${Uri.encodeComponent(name)}_$i=$chunk; path=/; max-age=$maxAge; SameSite=Lax$secureStr';
    }
  }

  /// Deletes all chunks of the cookie.
  void _deleteCookie(String name) {
    final isSecure = web.window.location.protocol == 'https:';
    final secureStr = isSecure ? '; Secure' : '';
    
    // Delete the count and up to 10 chunks to be safe
    web.document.cookie = '${Uri.encodeComponent(name)}_count=; path=/; max-age=0; SameSite=Lax$secureStr';
    for (int i = 0; i < 10; i++) {
      web.document.cookie = '${Uri.encodeComponent(name)}_$i=; path=/; max-age=0; SameSite=Lax$secureStr';
    }
    // Also delete the non-chunked version just in case
    web.document.cookie = '${Uri.encodeComponent(name)}=; path=/; max-age=0; SameSite=Lax$secureStr';
  }
}
