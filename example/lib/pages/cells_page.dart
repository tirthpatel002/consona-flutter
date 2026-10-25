import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';

class CellsPage extends StatefulWidget {
  const CellsPage({super.key});

  @override
  State<CellsPage> createState() => _CellsPageState();
}

class _CellsPageState extends State<CellsPage> {
  bool _biometricEnabled = true;
  bool _hapticCuesEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final shell = ConsonaShellScope.maybeOf(context);
    final bottomInset = (shell?.isFloating ?? false) ? 100.0 : 20.0;

    return ListView(
      padding: EdgeInsets.only(top: 20.0, bottom: bottomInset),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsonaText.hero('Cells & Sections'),
              SizedBox(height: 4.0),
              ConsonaText.caption(
                'Workhorse mobile list tiles, grouped card sections, and elastic swipe actions.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),

        // 1. Account Settings Group
        ConsonaSection(
          header: 'Account & Security',
          footer: 'Tap tiles to test micro-spring tactile press highlighting.',
          children: [
            ConsonaListTile(
              leading: Icon(Icons.person_outline, color: theme.colors.primary),
              title: 'Personal Information',
              subtitle: 'Update your display name and email address',
              onTap: () {},
            ),
            ConsonaListTile(
              leading: Icon(Icons.shield_outlined, color: theme.colors.primary),
              title: 'Two-Factor Authentication',
              subtitle: 'Secured via Authenticator App',
              trailing: const ConsonaBadge(
                label: 'Active',
                intent: ConsonaIntent.success,
              ),
              onTap: () {},
            ),
            ConsonaListTile(
              leading: Icon(Icons.fingerprint, color: theme.colors.primary),
              title: 'Biometric Unlock',
              subtitle: 'Face ID / Fingerprint fast login',
              showDivider: false,
              trailing: ConsonaSwitch(
                value: _biometricEnabled,
                onChanged: (val) => setState(() => _biometricEnabled = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // 2. Elastic Swipe Actions
        ConsonaSection(
          header: 'Swipe Actions (Elastic Snap)',
          footer: 'Swipe left on the tiles below to feel the haptic snap threshold.',
          children: [
            ConsonaSwipeAction(
              endActions: [
                ConsonaSwipeItem(
                  icon: const Icon(Icons.archive_outlined),
                  backgroundColor: const Color(0xFF2563EB),
                  onTap: () {},
                ),
                ConsonaSwipeItem(
                  icon: const Icon(Icons.delete_outline),
                  backgroundColor: const Color(0xFFDC2626),
                  onTap: () {},
                ),
              ],
              child: ConsonaListTile(
                leading: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline, size: 18.0),
                ),
                title: 'Swipe left to archive or delete',
                subtitle: 'Haptic snap occurs when crossing 72pt threshold',
                onTap: () {},
              ),
            ),
            ConsonaSwipeAction(
              endActions: [
                ConsonaSwipeItem(
                  icon: const Icon(Icons.star_outline),
                  backgroundColor: const Color(0xFFD97706),
                  onTap: () {},
                ),
                ConsonaSwipeItem(
                  icon: const Icon(Icons.delete_outline),
                  backgroundColor: const Color(0xFFDC2626),
                  onTap: () {},
                ),
              ],
              child: ConsonaListTile(
                leading: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_outlined, size: 18.0),
                ),
                title: 'Transaction Invoice #8291',
                subtitle: 'Paid \$49.00 USD on Oct 10',
                showDivider: false,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // 3. System Preferences Group
        ConsonaSection(
          header: 'System Preferences',
          children: [
            ConsonaListTile(
              leading: Icon(Icons.volume_up_outlined, color: theme.colors.mutedFg),
              title: 'Sensory Haptic Cues',
              trailing: ConsonaSwitch(
                value: _hapticCuesEnabled,
                onChanged: (val) => setState(() => _hapticCuesEnabled = val),
              ),
            ),
            ConsonaListTile(
              leading: Icon(Icons.language_outlined, color: theme.colors.mutedFg),
              title: 'Language',
              trailing: const ConsonaText.body('English (US)'),
              onTap: () {},
            ),
            ConsonaListTile(
              leading: Icon(Icons.storage_outlined, color: theme.colors.mutedFg),
              title: 'Cache & Local Storage',
              subtitle: '12.4 MB in use',
              showDivider: false,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
