import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

/// Settings page with genuine application preferences.
class SettingsPage extends StatefulWidget {
  final WisteriaDatabase database;

  const SettingsPage({super.key, required this.database});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WisteriaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const WisteriaBackButton(),
                  const Spacer(),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: WisteriaColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: WisteriaColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  WisteriaRadius.md,
                                ),
                                border: Border.all(
                                  color: WisteriaColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: WisteriaColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: WisteriaColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Application preferences',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: WisteriaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Appearance ──
                        _buildSection(
                          title: 'Appearance',
                          icon: Icons.palette_outlined,
                          children: [
                            _buildSettingRow(
                              label: 'Theme',
                              description: 'Application visual theme',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: WisteriaColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(
                                    WisteriaRadius.sm,
                                  ),
                                  border: Border.all(
                                    color: WisteriaColors.border,
                                  ),
                                ),
                                child: const Text(
                                  'Dark',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: WisteriaColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Application ──
                        _buildSection(
                          title: 'Application',
                          icon: Icons.computer_rounded,
                          children: [
                            _buildSettingRow(
                              label: 'Version',
                              description: 'Wisteria Clinical AI Workstation',
                              trailing: const Text(
                                '1.0.0',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: WisteriaColors.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const Divider(
                              color: WisteriaColors.border,
                              height: 32,
                            ),
                            _buildSettingRow(
                              label: 'Runtime',
                              description: 'AI inference engine',
                              trailing: const Text(
                                'ONNX Runtime',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: WisteriaColors.textSecondary,
                                ),
                              ),
                            ),
                            const Divider(
                              color: WisteriaColors.border,
                              height: 32,
                            ),
                            _buildSettingRow(
                              label: 'Storage',
                              description: 'Local database engine',
                              trailing: const Text(
                                'SQLite (Drift)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: WisteriaColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: WisteriaColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WisteriaColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String description,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: WisteriaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: WisteriaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
