import 'dart:async';

import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';

class AtomsPage extends StatefulWidget {
  const AtomsPage({super.key});

  @override
  State<AtomsPage> createState() => _AtomsPageState();
}

class _AtomsPageState extends State<AtomsPage> {
  bool _switchVal1 = true;
  bool _switchVal2 = false;
  bool _switchVal3 = true;
  bool _checkVal1 = true;
  bool _checkVal2 = false;
  String _radioVal = 'standard';
  bool _chipSelected1 = true;
  bool _chipSelected2 = false;
  int _selectedTier = 1;
  bool _loadingState = false;
  bool _removableChip = true;
  Timer? _loadingTimer;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _runLoading() {
    // A loading button is intentionally non-interactive, so it must reset
    // itself (otherwise the demo would be stuck in the loading state).
    setState(() => _loadingState = true);
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loadingState = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              ConsonaText.hero('Atoms Gallery'),
              SizedBox(height: 4.0),
              ConsonaText.caption(
                'Production-grade atoms with fail-closed defaults and micro-spring physics.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),

        // 1. Buttons
        ConsonaSection(
          header: 'Buttons & Variants',
          footer: 'Tap any button to experience micro-spring compression and sound cues.',
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaButton.primary(
                    label: 'Primary',
                    onTap: () {},
                  ),
                  ConsonaButton.subtle(
                    label: 'Subtle',
                    onTap: () {},
                  ),
                  ConsonaButton.outline(
                    label: 'Outline',
                    onTap: () {},
                  ),
                  ConsonaButton.plain(
                    label: 'Plain',
                    onTap: () {},
                  ),
                  ConsonaButton.danger(
                    label: 'Danger',
                    onTap: () {},
                  ),
                  ConsonaButton.primary(
                    label: 'Run (2s loading)',
                    loading: _loadingState,
                    onTap: _runLoading,
                  ),
                  const ConsonaButton.primary(label: 'Disabled', disabled: true),
                  const ConsonaButton.subtle(label: 'Disabled', disabled: true),
                  const ConsonaButton.outline(label: 'Disabled', disabled: true),
                  const ConsonaButton.danger(label: 'Disabled', disabled: true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 2. Optical Sizing & Shapes
        ConsonaSection(
          header: 'Optical Sizing & Shapes',
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaButton.subtle(
                    label: 'XS',
                    size: ConsonaOpticalSize.xs,
                    onTap: () {},
                  ),
                  ConsonaButton.subtle(
                    label: 'SM',
                    size: ConsonaOpticalSize.sm,
                    onTap: () {},
                  ),
                  ConsonaButton.subtle(
                    label: 'MD',
                    size: ConsonaOpticalSize.md,
                    onTap: () {},
                  ),
                  ConsonaButton.subtle(
                    label: 'LG',
                    size: ConsonaOpticalSize.lg,
                    onTap: () {},
                  ),
                  ConsonaButton.primary(
                    label: 'Base',
                    shapeVariant: ConsonaShapeVariant.base,
                    onTap: () {},
                  ),
                  ConsonaButton.primary(
                    label: 'Squircle',
                    shapeVariant: ConsonaShapeVariant.squircle,
                    onTap: () {},
                  ),
                  ConsonaButton.primary(
                    label: 'Inset',
                    shapeVariant: ConsonaShapeVariant.inset,
                    onTap: () {},
                  ),
                  ConsonaButton.primary(
                    label: 'Pill Shape',
                    shapeVariant: ConsonaShapeVariant.pill,
                    onTap: () {},
                  ),
                  ConsonaIconButton.subtle(
                    icon: const Icon(Icons.favorite_border),
                    size: ConsonaOpticalSize.sqXs,
                    onTap: () {},
                  ),
                  ConsonaIconButton.subtle(
                    icon: const Icon(Icons.favorite_border),
                    size: ConsonaOpticalSize.sqSm,
                    onTap: () {},
                  ),
                  ConsonaIconButton.outline(
                    icon: const Icon(Icons.favorite_border),
                    size: ConsonaOpticalSize.sqMd,
                    onTap: () {},
                  ),
                  ConsonaIconButton.outline(
                    icon: const Icon(Icons.favorite_border),
                    size: ConsonaOpticalSize.sqLg,
                    shapeVariant: ConsonaShapeVariant.pill,
                    onTap: () {},
                  ),
                  const ConsonaIconButton.plain(
                    icon: Icon(Icons.favorite_border),
                    disabled: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 3. Selection Controls: Switch, Checkbox, Radio
        ConsonaSection(
          header: 'Toggles & Selectors',
          footer: 'Switches feature squash-and-stretch thumbs; checkboxes draw in vector paths.',
          children: [
            ConsonaListTile(
              title: 'Bi-Tonal Switch (Active)',
              subtitle: 'Plays toggle_on / toggle_off synth cues',
              trailing: ConsonaSwitch(
                value: _switchVal1,
                onChanged: (val) => setState(() => _switchVal1 = val),
              ),
            ),
            ConsonaListTile(
              title: 'Inactive Switch',
              trailing: ConsonaSwitch(
                value: _switchVal2,
                onChanged: (val) => setState(() => _switchVal2 = val),
              ),
            ),
            ConsonaListTile(
              title: 'Glider Switch (ON / OFF)',
              subtitle: 'Sliding pill glider background behind text (no thumb)',
              trailing: ConsonaSwitch.labeled(
                value: _switchVal3,
                onChanged: (val) => setState(() => _switchVal3 = val),
              ),
            ),
            ConsonaListTile(
              title: 'Vector Draw Checkbox',
              subtitle: 'Animated checkmark path with spring pop',
              trailing: ConsonaCheckbox(
                value: _checkVal1,
                onChanged: (val) => setState(() => _checkVal1 = val),
              ),
            ),
            ConsonaListTile(
              title: 'Secondary Checkbox',
              trailing: ConsonaCheckbox(
                value: _checkVal2,
                onChanged: (val) => setState(() => _checkVal2 = val),
              ),
            ),
            ConsonaListTile(
              title: 'Radio Option A (Standard)',
              trailing: ConsonaRadio<String>(
                value: 'standard',
                groupValue: _radioVal,
                onChanged: (val) => setState(() => _radioVal = val!),
              ),
            ),
            ConsonaListTile(
              title: 'Radio Option B (Pro)',
              trailing: ConsonaRadio<String>(
                value: 'pro',
                groupValue: _radioVal,
                onChanged: (val) => setState(() => _radioVal = val!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ConsonaText.body('Disabled controls'),
                  const SizedBox(height: 2.0),
                  const ConsonaText.caption('Switch, checkbox and radio (selected + unselected)'),
                  const SizedBox(height: 8.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: [
                      ConsonaSwitch(value: true, onChanged: (_) {}, disabled: true),
                      ConsonaCheckbox(value: true, onChanged: (_) {}, disabled: true),
                      ConsonaCheckbox(value: false, onChanged: (_) {}, disabled: true),
                      ConsonaRadio<String>(
                        value: 'standard',
                        groupValue: 'standard',
                        onChanged: (_) {},
                        disabled: true,
                      ),
                      ConsonaRadio<String>(
                        value: 'pro',
                        groupValue: 'standard',
                        onChanged: (_) {},
                        disabled: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 4. Badges, Chips & Keyboard Atom
        ConsonaSection(
          header: 'Badges, Chips & Atoms',
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  const ConsonaBadge.dot(intent: ConsonaIntent.success, pulse: true),
                  const ConsonaBadge.dot(intent: ConsonaIntent.warning, pulse: false),
                  const ConsonaBadge.dot(intent: ConsonaIntent.danger, pulse: true),
                  const ConsonaBadge(label: 'Beta', intent: ConsonaIntent.primary),
                  const ConsonaBadge(count: 99, intent: ConsonaIntent.subtle),
                  ConsonaChip(
                    label: 'Selected Tag',
                    selected: _chipSelected1,
                    onTap: () => setState(() => _chipSelected1 = !_chipSelected1),
                  ),
                  ConsonaChip(
                    label: 'Filter Tag',
                    selected: _chipSelected2,
                    onTap: () => setState(() => _chipSelected2 = !_chipSelected2),
                  ),
                  if (_removableChip)
                    ConsonaChip(
                      label: 'Removable',
                      onDelete: () => setState(() => _removableChip = false),
                    )
                  else
                    ConsonaChip(
                      label: 'Restore chip',
                      onTap: () => setState(() => _removableChip = true),
                    ),
                  const ConsonaChip(label: 'Disabled', disabled: true),
                  const ConsonaChip(label: 'Disabled on', selected: true, disabled: true),
                  const ConsonaBadge(label: 'Danger', intent: ConsonaIntent.danger),
                  const ConsonaBadge(label: 'Success', intent: ConsonaIntent.success),
                  const ConsonaBadge(label: 'Warning', intent: ConsonaIntent.warning),
                  const ConsonaKbd('⌘K'),
                  const ConsonaKbd('Shift+P'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 5. Choice Box
        ConsonaSection(
          header: 'Choice Box Primitive',
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  ConsonaChoiceBox(
                    title: 'Starter Tier',
                    description: 'Basic cloud syncing and essential components.',
                    selected: _selectedTier == 1,
                    onTap: () => setState(() => _selectedTier = 1),
                  ),
                  const SizedBox(height: 10.0),
                  ConsonaChoiceBox(
                    title: 'Pro Enterprise',
                    description: 'High-speed audio engines, custom tokens, and priority slots.',
                    selected: _selectedTier == 2,
                    onTap: () => setState(() => _selectedTier = 2),
                  ),
                  const SizedBox(height: 10.0),
                  const ConsonaChoiceBox(
                    title: 'Legacy (disabled)',
                    description: 'Not available on this plan.',
                    selected: false,
                    disabled: true,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 6. Typography & Copyable
        const ConsonaSection(
          header: 'Typography & Clipboard',
          children: [
            Padding(
              padding: EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConsonaText.hero('Hero Headline'),
                  SizedBox(height: 6.0),
                  ConsonaText.titleLarge('Title Large Heading'),
                  SizedBox(height: 6.0),
                  ConsonaText.titleMedium('Title Medium Subhead'),
                  SizedBox(height: 6.0),
                  ConsonaText.body('Body text rendered with tabular numerical awareness.'),
                  SizedBox(height: 6.0),
                  ConsonaText.caption('Caption text scaled proportionally.'),
                  SizedBox(height: 12.0),
                  ConsonaCopyable(
                    textToCopy: 'curl https://consona.dev/api/v1',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 7. Shimmer Skeletons & Loaders
        const ConsonaSection(
          header: 'Loaders & Gradient Shimmer',
          children: [
            Padding(
              padding: EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ConsonaLoader(size: 24.0),
                      SizedBox(width: 14.0),
                      ConsonaLoader(size: 32.0, strokeWidth: 3.0),
                      SizedBox(width: 14.0),
                      Flexible(child: ConsonaText.body('Geometric micro-spinners')),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      ConsonaSkeleton.circular(size: 40.0),
                      SizedBox(width: 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConsonaSkeleton.text(width: 140.0),
                          SizedBox(height: 6.0),
                          ConsonaSkeleton.text(width: 90.0, height: 12.0),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.0),
                  // No hardcoded radius: the skeleton follows the theme radius knob.
                  ConsonaSkeleton(width: double.infinity, height: 50.0),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 8. Identity Avatars & Stacked Groups
        const ConsonaSection(
          header: 'Identity Avatars & Presence',
          footer: 'Circular & squircle avatars with presence badges and +N group stacks.',
          children: [
            Padding(
              padding: EdgeInsets.all(14.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14.0,
                runSpacing: 12.0,
                children: [
                  ConsonaAvatar(
                    name: 'Aria Vance',
                    size: ConsonaAvatarSize.sm,
                    status: ConsonaAvatarStatus.online,
                  ),
                  ConsonaAvatar(
                    name: 'Kaelen Thorne',
                    size: ConsonaAvatarSize.md,
                    status: ConsonaAvatarStatus.busy,
                  ),
                  ConsonaAvatar(
                    name: 'Soren Lind',
                    size: ConsonaAvatarSize.lg,
                    status: ConsonaAvatarStatus.away,
                    squircle: true,
                  ),
                  ConsonaAvatarGroup(
                    maxVisible: 3,
                    avatars: [
                      ConsonaAvatar(name: 'Aria Vance'),
                      ConsonaAvatar(name: 'Kaelen Thorne'),
                      ConsonaAvatar(name: 'Soren Lind'),
                      ConsonaAvatar(name: 'Mira Solis'),
                      ConsonaAvatar(name: 'Devon Park'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 9. Progress & Segmented Capacity Meters
        const ConsonaSection(
          header: 'Progress & Capacity Meters',
          footer: 'Determinate bars and threshold-aware segmented meters.',
          children: [
            Padding(
              padding: EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConsonaProgress(
                    value: 0.68,
                    label: 'Asset Bundle Sync',
                    showPercentage: true,
                  ),
                  SizedBox(height: 14.0),
                  ConsonaMeter(
                    value: 0.82,
                    label: 'DSP Buffer Load',
                    segments: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
