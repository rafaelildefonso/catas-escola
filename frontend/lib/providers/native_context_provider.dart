import 'package:flutter/foundation.dart'
    show ChangeNotifier, kIsWeb, debugPrint;

import '../core/context/native_context_model.dart';
import '../core/context/native_context_service.dart';

/// Provider that exposes the latest [NativeContext] to the widget tree.
///
/// On platforms without native support (e.g. web) this is a safe no-op.
class NativeContextProvider extends ChangeNotifier {
  final NativeContextService _service;
  NativeContext? _current;

  NativeContext? get current => _current;

  /// Whether the native context stream is actively collecting data.
  bool get isActive => _isActive;
  bool _isActive = false;

  NativeContextProvider({NativeContextService? service})
    : _service = service ?? NativeContextServiceImpl() {
    if (!kIsWeb) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      await _service.init();
      _isActive = true;
      _service.watchContext().listen((ctx) {
        _current = ctx;
        notifyListeners();
      });
      debugPrint('[NativeContextProvider] Context stream started');
    } catch (e) {
      // Gracefully handle missing native implementation
      debugPrint(
        '[NativeContextProvider] Init failed (expected on unsupported platforms): $e',
      );
    }
  }

  /// Convenience getters used by ChatProvider to attach context to messages.
  String? get currentPageUrl => _current?.browserUrl;
  String? get currentPageTitle => _current?.foregroundAppName;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
