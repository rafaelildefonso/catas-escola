import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Breakpoints para responsividade
class Breakpoints {
  /// Largura máxima para ser considerado layout de celular
  static const double mobile = 600;

  /// Largura máxima para ser considerado layout de tablet
  static const double tablet = 1024;

  /// Largura mínima em que o layout passa a ser de desktop "amplo"
  static const double desktop = 1200;
}

/// Helpers para verificar tamanho de tela
bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < Breakpoints.mobile;

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= Breakpoints.mobile && width < Breakpoints.tablet;
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// Retorna true se estiver rodando em web
bool get isWeb => kIsWeb;

/// Helper para obter largura máxima de conteúdo em desktop
double getMaxContentWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= Breakpoints.desktop) {
    return 900;
  } else if (width >= Breakpoints.tablet) {
    return 700;
  }
  return width;
}
