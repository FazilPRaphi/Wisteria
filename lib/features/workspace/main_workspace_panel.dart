import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/theme/wisteria_theme.dart';
import '../patients/patient_page.dart';

/// Panel A — Main Workspace
///
/// Two large cards: Patients and AI Workplace.
class MainWorkspacePanel extends StatelessWidget {
  final WisteriaDatabase database;

  const MainWorkspacePanel({super.key, required this.database});

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
                  // ── Greeting ──
                  _buildGreeting(),

                  const SizedBox(height: 48),

                  // ── Main cards ──
                  Expanded(
                    child: _buildMainCards(context, constraints.maxWidth),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back, Doctor',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: WisteriaColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your clinical workspace',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: WisteriaColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCards(BuildContext context, double maxWidth) {
    final isNarrow = maxWidth < 700;

    if (isNarrow) {
      return Column(
        children: [
          Expanded(
            child: _WorkspaceHeroCard(
              title: 'Patients',
              subtitle: 'Manage patient records, registrations, and profiles',
              icon: Icons.people_rounded,
              accentColor: WisteriaColors.primary,
              onTap: () => _navigateToPatients(context),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _WorkspaceHeroCard(
              title: 'AI Workplace',
              subtitle:
                  'Run AI-assisted diagnostics on medical imaging studies',
              icon: Icons.auto_awesome_rounded,
              accentColor: WisteriaColors.tertiary,
              onTap: () => _navigateToAIWorkplace(context),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _WorkspaceHeroCard(
            title: 'Patients',
            subtitle: 'Manage patient records, registrations, and profiles',
            icon: Icons.people_rounded,
            accentColor: WisteriaColors.primary,
            onTap: () => _navigateToPatients(context),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _WorkspaceHeroCard(
            title: 'AI Workplace',
            subtitle: 'Run AI-assisted diagnostics on medical imaging studies',
            icon: Icons.auto_awesome_rounded,
            accentColor: WisteriaColors.tertiary,
            onTap: () => _navigateToAIWorkplace(context),
          ),
        ),
      ],
    );
  }

  void _navigateToPatients(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PatientPage(database: database),
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

  void _navigateToAIWorkplace(BuildContext context) {
    // AI Workplace navigates to the patient workspace since examinations
    // are patient-linked. This provides a clear entry point to the
    // existing examination + inference workflow.
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PatientPage(database: database),
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

/// Large, visually prominent hero card for main workspace actions.
class _WorkspaceHeroCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _WorkspaceHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_WorkspaceHeroCard> createState() => _WorkspaceHeroCardState();
}

class _WorkspaceHeroCardState extends State<_WorkspaceHeroCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
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
              offset: Offset(0, -3 * t),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor.withValues(alpha: 0.10 + (0.05 * t)),
                      WisteriaColors.surfaceLow,
                      WisteriaColors.surfaceLow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(WisteriaRadius.xl),
                  border: Border.all(
                    color: _isHovered
                        ? widget.accentColor.withValues(alpha: 0.5)
                        : widget.accentColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12 + (20 * t),
                      spreadRadius: -4,
                      offset: Offset(0, 4 + (8 * t)),
                      color: Colors.black.withValues(alpha: 0.20 + (0.10 * t)),
                    ),
                    BoxShadow(
                      blurRadius: 32 + (12 * t),
                      spreadRadius: -8,
                      offset: Offset(0, 6 + (6 * t)),
                      color: widget.accentColor.withValues(
                        alpha: 0.06 + (0.12 * t),
                      ),
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
              // ── Icon ──
              _buildIcon(),

              const Spacer(),

              // ── Title ──
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: WisteriaColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 10),

              // ── Subtitle ──
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: WisteriaColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              // ── Action hint ──
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: widget.accentColor,
                  ),
                ],
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _isHovered
            ? widget.accentColor.withValues(alpha: 0.18)
            : widget.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(
          color: _isHovered
              ? widget.accentColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 30,
        color: _isHovered
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: 0.8),
      ),
    );
  }
}
