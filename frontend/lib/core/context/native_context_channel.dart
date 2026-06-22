import 'dart:async';

import 'package:flutter/services.dart';

import 'native_context_model.dart';

/// Nomes dos canais usados para comunicação com código nativo.
class NativeContextChannels {
  static const methodChannelName = 'com.catas/native_context';
  static const streamChannelName = 'com.catas/native_context_stream';

  static const methodGetCurrentContext = 'getCurrentContext';
  static const methodStartContextStream = 'startContextStream';
  static const methodStopContextStream = 'stopContextStream';
}

/// Fachada sobre MethodChannel/EventChannel para contexto nativo.
class NativeContextChannel {
  NativeContextChannel()
      : _methodChannel =
            const MethodChannel(NativeContextChannels.methodChannelName),
        _eventChannel =
            const EventChannel(NativeContextChannels.streamChannelName);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<NativeContext> watchContext() {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event != null)
        .map((event) => Map<String, dynamic>.from(event as Map))
        .map(NativeContext.fromJson);
  }

  Future<void> startContextStream() {
    return _methodChannel
        .invokeMethod(NativeContextChannels.methodStartContextStream);
  }

  Future<void> stopContextStream() {
    return _methodChannel
        .invokeMethod(NativeContextChannels.methodStopContextStream);
  }

  Future<NativeContext?> getCurrentContext() async {
    final result = await _methodChannel
        .invokeMethod<Map<dynamic, dynamic>?>(NativeContextChannels.methodGetCurrentContext);
    if (result == null) return null;
    return NativeContext.fromJson(Map<String, dynamic>.from(result));
  }
}

