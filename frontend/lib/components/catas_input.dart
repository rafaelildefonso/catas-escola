import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatasInput extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final int? maxLength;
  final bool showCounter;

  const CatasInput({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofocus = false,
    this.maxLength,
    this.showCounter = false,
  });

  @override
  State<CatasInput> createState() => _CatasInputState();
}

class _CatasInputState extends State<CatasInput> {
  late TextEditingController _controller;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _currentLength = _controller.text.length;
    _controller.addListener(_updateLength);
  }

  void _updateLength() {
    if (mounted) {
      setState(() {
        _currentLength = _controller.text.length;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateLength);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CatasInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_updateLength);
      _controller = widget.controller ?? TextEditingController();
      _currentLength = _controller.text.length;
      _controller.addListener(_updateLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Lógica para feedback de cor baseado no limite
    Color? borderColor;
    if (widget.maxLength != null && _currentLength > 0) {
      final progress = _currentLength / widget.maxLength!;
      if (progress > 0.7) {
        // Interpolação linear para vermelho entre 70% e 100% do limite
        final intensity = (progress - 0.7) / 0.3;
        borderColor = Color.lerp(
          theme.colorScheme.outline.withValues(alpha: 0.15),
          Colors.redAccent,
          intensity,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _controller,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
            maxLength: widget.maxLength,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              counterText: '', // Esconde o contador padrão
              hintText: widget.hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (widget.showCounter && widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Text(
              '$_currentLength / ${widget.maxLength}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: borderColor?.withValues(alpha: 0.8) ??
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
