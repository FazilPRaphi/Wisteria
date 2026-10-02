import 'package:flutter/material.dart';

import '../../core/theme/wisteria_theme.dart';

/// Consistent back button used across Wisteria sub-pages.
/// Styled with the premium dark theme and hover effects.
class WisteriaBackButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const WisteriaBackButton({super.key, this.label = 'Dashboard', this.onTap});

  @override
  State<WisteriaBackButton> createState() => _WisteriaBackButtonState();
}

class _WisteriaBackButtonState extends State<WisteriaBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () => Navigator.of(context).pop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? WisteriaColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(WisteriaRadius.md),
            border: Border.all(
              color: _isHovered
                  ? WisteriaColors.primary.withValues(alpha: 0.2)
                  : WisteriaColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: _isHovered
                    ? WisteriaColors.primary
                    : WisteriaColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isHovered
                      ? WisteriaColors.primary
                      : WisteriaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
