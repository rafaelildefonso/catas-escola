import 'package:flutter/foundation.dart';

/// Representa um snapshot de contexto nativo do dispositivo.
@immutable
class NativeContext {
  final String? foregroundAppName;
  final String? foregroundAppId;
  final String? browserUrl;
  final DateTime capturedAt;

  const NativeContext({
    this.foregroundAppName,
    this.foregroundAppId,
    this.browserUrl,
    required this.capturedAt,
  });

NativeContext copyWith({
  String? foregroundAppName,
  String? foregroundAppId,
  String? browserUrl,
  DateTime? capturedAt,
}) {
  return NativeContext(
    foregroundAppName: foregroundAppName ?? this.foregroundAppName,
    foregroundAppId: foregroundAppId ?? this.foregroundAppId,
    browserUrl: browserUrl ?? this.browserUrl,
    capturedAt: capturedAt ?? this.capturedAt,
  );
}

  Map<String, dynamic> toJson() => {
    'foregroundAppName': foregroundAppName,
    'foregroundAppId': foregroundAppId,
    'browserUrl': browserUrl,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory NativeContext.fromJson(Map<String, dynamic> json) {
    return NativeContext(
      foregroundAppName: json['foregroundAppName'] as String?,
      foregroundAppId: json['foregroundAppId'] as String?,
      browserUrl: json['browserUrl'] as String?,
      capturedAt:
          DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
