import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ConcordTextField extends StatefulWidget {
  const ConcordTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<ConcordTextField> createState() => _ConcordTextFieldState();
}

class _ConcordTextFieldState extends State<ConcordTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final invalid = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              style: textTheme.labelLarge,
              children: [
                TextSpan(text: widget.label),
                if (widget.required)
                  TextSpan(text: ' *', style: TextStyle(color: colors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText && !_visible,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: textTheme.bodyMedium?.copyWith(color: colors.fgDefault),
          cursorColor: colors.brand,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: colors.fgMuted,
                    ),
                    tooltip: _visible ? 'Hide password' : 'Show password',
                    onPressed: () => setState(() => _visible = !_visible),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              borderSide: BorderSide(color: invalid ? colors.danger : colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              borderSide: BorderSide(color: invalid ? colors.danger : colors.brand, width: 2),
            ),
          ),
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.errorText!, style: textTheme.bodySmall?.copyWith(color: colors.danger)),
        ],
      ],
    );
  }
}
