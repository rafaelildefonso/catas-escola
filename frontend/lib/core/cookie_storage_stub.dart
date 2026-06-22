import 'package:supabase_flutter/supabase_flutter.dart';

/// Stub cookie storage for non-web platforms.
/// This prevents compilation errors on mobile because dart:html / package:web
/// cannot be compiled for Android/iOS.
/// This class will not be used on mobile because we check kIsWeb in main.dart.
class CookieSupabaseStorage extends LocalStorage {
  const CookieSupabaseStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}
