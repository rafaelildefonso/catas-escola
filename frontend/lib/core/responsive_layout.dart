import 'package:flutter/material.dart';

import 'responsive.dart';

/// Widget genérico para trocar entre layouts mobile/tablet/desktop
/// usando os breakpoints centrais do app.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile(context)) {
      return mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return desktop;
  }
}

