import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design_tokens.dart';

class SettingsSubScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const SettingsSubScreen({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.catasTokens.canvas,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.catasTokens.canvas,
        elevation: 0,
        actions: actions,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
