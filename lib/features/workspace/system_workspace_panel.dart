import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/theme/wisteria_theme.dart';
import '../doctor/doctor_profile_page.dart';
import '../models/medical_model_page.dart';
import '../shared/placeholder_page.dart';
import 'settings_page.dart';

/// Panel B — Doctor & System Workspace
///
/// Contains: Doctor Profile, Settings, Models, Sync.
class SystemWorkspacePanel extends StatelessWidget {
  final WisteriaDatabase database;

  const SystemWorkspacePanel({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // ── System cards grid ──
                  Expanded(child: _buildGrid(context, constraints.maxWidth)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor & System',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: WisteriaColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Profile, settings, models, and synchronization',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: WisteriaColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, double maxWidth) {
    final isNarrow = maxWidth < 700;

    final cards = [
      _SystemCard(
        title: 'Doctor Profile',
        subtitle: 'Manage your professional profile and clinic information',
        icon: Icons.person_rounded,
        accentColor: WisteriaColors.tertiary,
        onTap: () => _navigate(context, DoctorProfilePage(database: database)),
      ),
      _SystemCard(
        title: 'Settings',
        subtitle: 'Application preferences and configuration',
        icon: Icons.settings_rounded,
        accentColor: WisteriaColors.primary,
        onTap: () => _navigate(context, SettingsPage(database: database)),
      ),
      _SystemCard(
        title: 'Models',
        subtitle: 'View preinstalled local AI models',
        icon: Icons.memory_rounded,
        accentColor: const Color(0xFF38BDF8),
        onTap: () => _navigate(context, MedicalModelPage(database: database)),
      ),
      _SystemCard(
        title: 'Sync',
        subtitle: 'Data synchronization across workstations',
        icon: Icons.sync_rounded,
        accentColor: WisteriaColors.success,
        onTap: () => _navigate(
          context,
          const PlaceholderPage(
            title: 'Data Synchronization',
            subtitle: 'Synchronize clinical data across your workstations.',
            icon: Icons.sync_rounded,
          ),
        ),
      ),
    ];

    if (isNarrow) {
      return ListView(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(height: 180, child: card),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 20),
              Expanded(child: cards[1]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 20),
              Expanded(child: cards[3]),
            ],
          ),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

/// System card for Panel B items.
class _SystemCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _SystemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<_SystemCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            return Transform.translate(
              offset: Offset(0, -2 * t),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: WisteriaColors.cardGradient,
                  borderRadius: BorderRadius.circular(WisteriaRadius.lg),
                  border: Border.all(
                    color: _isHovered
                        ? widget.accentColor.withValues(alpha: 0.45)
                        : WisteriaColors.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8 + (14 * t),
                      spreadRadius: -2,
                      offset: Offset(0, 2 + (5 * t)),
                      color: Colors.black.withValues(alpha: 0.20 + (0.08 * t)),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        blurRadius: 20 + (8 * t),
                        spreadRadius: -4,
                        offset: Offset(0, 4 + (4 * t)),
                        color: widget.accentColor.withValues(alpha: 0.08 * t),
                      ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),

              const Spacer(),

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: WisteriaColors.textMuted,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _isHovered
            ? widget.accentColor.withValues(alpha: 0.16)
            : widget.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        border: Border.all(
          color: _isHovered
              ? widget.accentColor.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 24,
        color: _isHovered
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: 0.8),
      ),
    );
  }
}
