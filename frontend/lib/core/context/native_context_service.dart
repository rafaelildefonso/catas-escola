import 'dart:async';

import 'package:flutter/foundation.dart';

import 'native_context_channel.dart';
import 'native_context_model.dart';

/// Serviço de alto nível usado pelo app para consumir contexto nativo.
abstract class NativeContextService {
  Stream<NativeContext> watchContext();
  Future<NativeContext?> getCurrentContext();
  Future<void> init();
  Future<void> dispose();
}

/// Implementação padrão baseada em MethodChannel/EventChannel.
class NativeContextServiceImpl implements NativeContextService {
  NativeContextServiceImpl({NativeContextChannel? channel})
      : _channel = channel ?? NativeContextChannel();

  final NativeContextChannel _channel;
  StreamSubscription<NativeContext>? _subscription;
  final ValueNotifier<NativeContext?> currentContext =
      ValueNotifier<NativeContext?>(null);

  @override
  Future<void> init() async {
    _subscription = _channel.watchContext().listen((ctx) {
      currentContext.value = ctx;
    });
    await _channel.startContextStream();
  }

  @override
  Stream<NativeContext> watchContext() {
    return _channel.watchContext();
  }

  @override
  Future<NativeContext?> getCurrentContext() async {
    final snapshot = await _channel.getCurrentContext();
    if (snapshot != null) {
      currentContext.value = snapshot;
    }
    return snapshot;
  }

  @override
  Future<void> dispose() async {
    await _channel.stopContextStream();
    await _subscription?.cancel();
  }
}

