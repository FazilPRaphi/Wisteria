import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/database/database.dart';
import '../../core/theme/wisteria_theme.dart';
import 'main_workspace_panel.dart';
import 'system_workspace_panel.dart';

/// Root two-panel horizontally sliding workspace.
///
/// Panel A: Main Workspace (Patients + AI Workplace)
/// Panel B: Doctor & System Workspace (Profile, Settings, Models, Sync)
class WorkspaceShell extends StatefulWidget {
  final WisteriaDatabase database;

  const WorkspaceShell({super.key, required this.database});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WisteriaColors.background,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                _currentPage == 0) {
              _goToPage(1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                _currentPage == 1) {
              _goToPage(0);
            }
          }
        },
        child: Stack(
          children: [
            // ── Page View ──
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              children: [
                MainWorkspacePanel(database: widget.database),
                SystemWorkspacePanel(database: widget.database),
              ],
            ),

            // ── Navigation indicator ──
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: _WorkspaceNavigationBar(
                currentPage: _currentPage,
                onPageSelected: _goToPage,
              ),
            ),

            // ── Edge navigation arrows ──
            if (_currentPage == 0)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: _EdgeArrow(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Doctor & System Workspace',
                  onTap: () => _goToPage(1),
                ),
              ),

            if (_currentPage == 1)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: _EdgeArrow(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Main Workspace',
                  onTap: () => _goToPage(0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Segmented navigation indicator at the bottom center.
class _WorkspaceNavigationBar extends StatelessWidget {
  final int currentPage;
  final void Function(int) onPageSelected;

  const _WorkspaceNavigationBar({
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: WisteriaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(WisteriaRadius.full),
          border: Border.all(color: WisteriaColors.border),
          boxShadow: WisteriaElevation.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavSegment(
              icon: Icons.dashboard_rounded,
              label: 'Workspace',
              isActive: currentPage == 0,
              onTap: () => onPageSelected(0),
            ),
            const SizedBox(width: 4),
            _NavSegment(
              icon: Icons.settings_rounded,
              label: 'Doctor & System',
              isActive: currentPage == 1,
              onTap: () => onPageSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual segment in the navigation bar.
class _NavSegment extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavSegment({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavSegment> createState() => _NavSegmentState();
}

class _NavSegmentState extends State<_NavSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? WisteriaColors.primaryMuted.withValues(alpha: 0.9)
                : _isHovered
                ? WisteriaColors.surfaceHigh
                : Colors.transparent,
            borderRadius: BorderRadius.circular(WisteriaRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? WisteriaColors.textOnPrimary
                    : _isHovered
                    ? WisteriaColors.textPrimary
                    : WisteriaColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isActive
                      ? WisteriaColors.textOnPrimary
                      : _isHovered
                      ? WisteriaColors.textPrimary
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

/// Subtle edge arrow button for panel navigation.
class _EdgeArrow extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _EdgeArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_EdgeArrow> createState() => _EdgeArrowState();
}

class _EdgeArrowState extends State<_EdgeArrow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 72,
              decoration: BoxDecoration(
                color: _isHovered
                    ? WisteriaColors.primary.withValues(alpha: 0.12)
                    : WisteriaColors.surfaceLow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(WisteriaRadius.md),
                border: Border.all(
                  color: _isHovered
                      ? WisteriaColors.primary.withValues(alpha: 0.3)
                      : WisteriaColors.border.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: _isHovered
                    ? WisteriaColors.primary
                    : WisteriaColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
