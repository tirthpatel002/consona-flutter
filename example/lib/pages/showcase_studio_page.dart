import 'dart:async';
import 'dart:typed_data';

import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';

/// Studio showcase — [ConsonaNav] tab bar synced with [ConsonaSwipeableTabPager].
class ShowcaseStudioPage extends StatefulWidget {
  const ShowcaseStudioPage({super.key});

  @override
  State<ShowcaseStudioPage> createState() => _ShowcaseStudioPageState();
}

class _ShowcaseStudioPageState extends State<ShowcaseStudioPage> {
  bool _toastStylesRegistered = false;

  // Phase 3 State
  int _counter = 3;
  num? _numberAmount = 12.5;
  String? _autocompleteCity = 'Berlin';
  bool _showBanner = true;
  double _rating = 4.5;
  double _sliderValue = 0.65;
  double _rangeSliderStart = 0.22;
  double _rangeSliderEnd = 0.78;
  String _segmentMode = 'studio';
  ConsonaCameraCaptureResult? _lastCameraCapture;
  int _currentStep = 1;
  String _selectedRole = 'Designer';
  DateTime _selectedDate = DateTime.now();
  DateTime? _rangeStart = DateTime.now();
  DateTime? _rangeEnd = DateTime.now().add(const Duration(days: 3));
  DateTime _selectedDateTime = DateTime.now().copyWith(hour: 14, minute: 30);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  int _wheelIndex = 2;
  CountryCode _selectedCountry =
      ConsonaCountryPickerSheet.defaultCountries.first;
  int _studioTab = 0;
  List<String> _tagsWrap = ['flutter', 'design-tokens', 'responsive'];
  List<String> _tagsRow = [
    'flutter',
    'design-tokens',
    'responsive',
    'audio',
    'tokens',
  ];
  Set<Object> _selectedTableRows = {'node-1'};
  Set<String> _multiRoles = {'Designer', 'Engineer'};
  Color _brandColor = const Color.fromARGB(255, 37, 99, 235);
  ConsonaFillType _fillType = ConsonaFillType.solid;
  ConsonaGradientConfig _brandGradient = kGradientPresets.first.config;
  ConsonaImageFillConfig _brandImage = const ConsonaImageFillConfig(
    url:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
  );
  List<String> _customColorSwatches = const [];
  Color _solidOnlyColor = const Color.fromARGB(255, 124, 58, 237);
  bool _bioExpanded = false;
  String _snippetTab = 'dart';
  String? _treeSelected = 'tokens';
  Set<String> _treeExpanded = {'design'};
  List<String> _infiniteItems =
      List.generate(12, (i) => 'Signal event ${i + 1}');
  bool _infiniteLoading = false;
  bool _infiniteHasMore = true;
  List<ConsonaUploadItem> _uploadItems = const [
    ConsonaUploadItem(
      name: 'stem_master_24bit.wav',
      sizeLabel: '18.4 MB',
      progress: 0.72,
    ),
    ConsonaUploadItem(
      name: 'preset_bank.json',
      sizeLabel: '142 KB',
      progress: 1.0,
    ),
  ];

  // Phase 4 Audio — each surface owns an isolated engine/backend runtime.
  late final AudioEngine _playerCardEngine;
  late final AudioEngine _playerPillEngine;
  late final AudioRecorderEngine _recorderCardEngine;
  late final AudioRecorderEngine _recorderPillEngine;
  late final ConsonaRecordingPreview _recorderCardPreview;
  late final ConsonaRecordingPreview _recorderPillPreview;

  static const _studioTabs =
      <({String id, String label, IconData icon, IconData selectedIcon})>[
    (
      id: 'forms',
      label: 'Forms',
      icon: Icons.edit_outlined,
      selectedIcon: Icons.edit
    ),
    (
      id: 'pickers',
      label: 'Pickers',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune
    ),
    (
      id: 'controls',
      label: 'Controls',
      icon: Icons.touch_app_outlined,
      selectedIcon: Icons.touch_app
    ),
    (
      id: 'overlays',
      label: 'Overlays',
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers
    ),
    (
      id: 'surfaces',
      label: 'Surfaces',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard
    ),
    (
      id: 'audio',
      label: 'Audio',
      icon: Icons.graphic_eq_outlined,
      selectedIcon: Icons.graphic_eq
    ),
    (
      id: 'media',
      label: 'Media',
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library
    ),
  ];

  static const _demoGalleryItems = [
    ConsonaMediaItem(
      id: 'img-1',
      name: 'mountain_landscape.jpg',
      caption: 'Alpine Ridge at Dusk',
      uri: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '2.4 MB',
    ),
    ConsonaMediaItem(
      id: 'img-2',
      name: 'misty_forest.jpg',
      caption: 'Pacific Northwest Canopy',
      uri: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '3.1 MB',
    ),
    ConsonaMediaItem(
      id: 'img-3',
      name: 'desert_dunes.jpg',
      caption: 'Sahara Golden Hour',
      uri: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '1.9 MB',
    ),
    ConsonaMediaItem(
      id: 'img-4',
      name: 'ocean_cliffs.jpg',
      caption: 'Atlantic Coastline',
      uri: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '4.2 MB',
    ),
    ConsonaMediaItem(
      id: 'img-5',
      name: 'aurora_borealis.jpg',
      caption: 'Tromsø Night Sky',
      uri: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '2.8 MB',
    ),
    ConsonaMediaItem(
      id: 'img-6',
      name: 'autumn_lake.jpg',
      caption: 'Lake Louise Reflection',
      uri: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=800&q=80',
      sizeLabel: '3.5 MB',
    ),
    ConsonaMediaItem(
      id: 'vid-1',
      name: 'pollinator_field.mp4',
      caption: 'Field clip — tap to play in lightbox',
      uri: 'asset:assets/videos/bee.mp4',
      thumbnailUri:
          'https://images.unsplash.com/photo-1470114716159-e389f8712fda?auto=format&fit=crop&w=400&q=80',
      sizeLabel: '1.2 MB',
    ),
  ];

  static const _demoFileItems = [
    ConsonaMediaItem(
      id: 'doc-1',
      name: 'consona_design_system_specs.pdf',
      sizeLabel: '4.8 MB',
    ),
    ConsonaMediaItem(
      id: 'code-1',
      name: 'theme_tokens.json',
      sizeLabel: '18.4 KB',
      textContent: '{\n  "name": "Consona Obsidian",\n  "version": "2.4.0",\n  "tokens": {\n    "radius": "squircle",\n    "border": "hairline",\n    "contrast": "wcag_aaa"\n  }\n}',
    ),
    ConsonaMediaItem(
      id: 'code-2',
      name: 'main.dart',
      sizeLabel: '2.1 KB',
      textContent: 'import \'package:flutter/material.dart\';\nimport \'package:consona_flutter/consona_flutter.dart\';\n\nvoid main() => runApp(const ConsonaApp());',
    ),
    ConsonaMediaItem(
      id: 'zip-1',
      name: 'vector_icons_pack.zip',
      sizeLabel: '14.2 MB',
    ),
  ];

  static const List<String> _wheelOptions = [
    'Low Latency (50ms)',
    'Balanced (120ms)',
    'High Fidelity (250ms)',
    'Extreme Dynamic (500ms)',
    'Adaptive Ultra (1000ms)',
  ];

  AudioTrack _demoTrack(Uint8List demoBytes) => AudioTrack(
        id: 'synth_wave',
        title: 'Neon Odyssey',
        artist: 'Consona Audio Labs',
        duration: const Duration(milliseconds: 2400),
        bytes: demoBytes,
        amplitudes: const [
          0.3,
          0.7,
          0.9,
          0.4,
          0.6,
          0.85,
          0.2,
          0.5,
          0.75,
          0.35,
          0.9,
          0.45,
        ],
      );

  AudioEngine _newPlayerEngine(String id) {
    return AudioEngine(
      id: id,
      backend: AudioplayersAudioBackend(playerId: 'consona_$id'),
    );
  }

  Future<void> _prepareAudio(AudioTrack track) async {
    await Future.wait([
      _playerCardEngine.load(track),
      _playerPillEngine.load(track),
    ]);
    await Future.wait([
      _playerCardEngine.setLooping(true),
      _playerPillEngine.setLooping(true),
    ]);
  }

  @override
  void initState() {
    super.initState();
    final demoBytes = buildDemoToneWav();
    final track = _demoTrack(demoBytes);
    _playerCardEngine = _newPlayerEngine('player_card');
    _playerPillEngine = _newPlayerEngine('player_pill');
    _recorderCardEngine = AudioRecorderEngine(
      id: 'recorder_card',
      backend: RecordAudioRecorderBackend(),
    );
    _recorderPillEngine = AudioRecorderEngine(
      id: 'recorder_pill',
      backend: RecordAudioRecorderBackend(),
    );
    _recorderCardPreview = ConsonaRecordingPreview(
      backend: AudioplayersAudioBackend(playerId: 'consona_preview_card'),
    );
    _recorderPillPreview = ConsonaRecordingPreview(
      backend: AudioplayersAudioBackend(playerId: 'consona_preview_pill'),
    );
    unawaited(_prepareAudio(track));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_toastStylesRegistered) return;
    _toastStylesRegistered = true;
    final toasts = ConsonaToastController.of(context);
    toasts.register(
      ConsonaToastStyle.custom(
        id: 'shipped',
        icon: Icons.local_shipping_rounded,
        accent: (t) => t.colors.success,
      ),
    );
    toasts.register(
      ConsonaToastStyle.custom(
        id: 'invite',
        icon: Icons.person_add_alt_1_rounded,
        accent: (t) => t.colors.primary,
        background: (t) => t.colors.surfaceSecondary,
      ),
    );
  }

  @override
  void dispose() {
    _playerCardEngine.dispose();
    _playerPillEngine.dispose();
    _recorderCardEngine.dispose();
    _recorderPillEngine.dispose();
    _recorderCardPreview.dispose();
    _recorderPillPreview.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateTime(DateTime d) {
    final t = TimeOfDay.fromDateTime(d);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = '${t.minute}'.padLeft(2, '0');
    final period = t.period == DayPeriod.pm ? 'PM' : 'AM';
    return '${_formatDate(d)} · $h:$m $period';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Select a range';
    if (end == null) return '${_formatDate(start)} → …';
    return '${_formatDate(start)} → ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final shell = ConsonaShellScope.maybeOf(context);
    final bottomInset =
        (shell?.isFloating ?? false) ? 120.0 : ConsonaSpacing.xxxl;
    final destinations = [
      for (final t in _studioTabs)
        ConsonaDestination(
          id: t.id,
          label: t.label,
          icon: t.icon,
          selectedIcon: t.selectedIcon,
          builder: (_) => const SizedBox.shrink(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ConsonaSpacing.base,
            ConsonaSpacing.sm,
            ConsonaSpacing.base,
            ConsonaSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Studio', style: theme.typography.titleMedium),
              const SizedBox(height: ConsonaSpacing.xxs),
              Text(
                'Tab bar + swipeable pager — tap or swipe. Glider by default.',
                style: theme.typography.caption
                    .copyWith(color: theme.colors.mutedFg),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ConsonaNav(
                destinations: destinations,
                selectedIndex: _studioTab,
                placement: ConsonaNavPlacement.top,
                variant: ConsonaNavVariant.bar,
                dense: true,
                size: ConsonaOpticalSize.xs,
                safeArea: false,
                fitContent: false,
                onSelect: (id) {
                  final i = destinations.indexWhere((d) => d.id == id);
                  if (i >= 0) setState(() => _studioTab = i);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: ConsonaSpacing.md),
        Expanded(
          child: ConsonaSwipeableTabPager(
            index: _studioTab,
            onIndexChanged: (i) => setState(() => _studioTab = i),
            itemCount: _studioTabs.length,
            itemBuilder: (context, index) {
              return _StudioTabScroll(
                bottomInset: bottomInset,
                child: _buildTabBody(context, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody(BuildContext context, int index) {
    return switch (index) {
      0 => _buildFormsTab(context),
      1 => _buildPickersTab(context),
      2 => _buildControlsTab(context),
      3 => _buildOverlaysTab(context),
      4 => _buildSurfacesTab(context),
      5 => _buildAudioTab(context),
      _ => _buildMediaTab(context),
    };
  }

  Widget _buildFormsTab(BuildContext context) {
    return ConsonaSection(
      header: 'Forms & Tactile Inputs',
      footer:
          'Tactile input wells, tag tokens, file dropzone, and PIN verification',
      children: [
        Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ConsonaTextField(
                label: 'Username',
                placeholder: 'e.g. alex_chen',
                helperText: 'Your unique handle across workspaces',
                clearable: true,
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaEmailField(
                placeholder: 'alex@company.com',
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaPasswordField(
                showStrengthMeter: true,
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaPhoneField(
                label: 'Mobile Number',
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaSearchField(
                placeholder: 'Search components, tokens, icons...',
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaNumberField(
                label: 'Seat Budget',
                value: _numberAmount,
                min: 0,
                max: 100,
                step: 0.5,
                decimalPlaces: 1,
                prefix: '\$',
                suffix: 'k',
                showSteppers: true,
                helperText: 'Typed amount with clamp + steppers',
                onChanged: (val) => setState(() => _numberAmount = val),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaAutocomplete<String>(
                label: 'Studio City',
                value: _autocompleteCity,
                placeholder: 'Type a city…',
                items: const [
                  'Amsterdam',
                  'Berlin',
                  'Copenhagen',
                  'Lisbon',
                  'London',
                  'New York',
                  'Paris',
                  'Tokyo',
                  'Toronto',
                ],
                onSelected: (city) => setState(() => _autocompleteCity = city),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaMultiSelect<String>(
                label: 'Team Disciplines',
                values: _multiRoles,
                items: const [
                  'Designer',
                  'Engineer',
                  'Product Manager',
                  'Researcher',
                  'Sound Artist',
                ],
                onChanged: (next) => setState(() => _multiRoles = next),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaSnippet(
                maxLines: 6,
                maxHeight: 220,
                selectedTabId: _snippetTab,
                onTabChanged: (id) => setState(() => _snippetTab = id),
                tabs: const [
                  ConsonaSnippetTab(
                    id: 'dart',
                    label: 'Dart',
                    language: 'dart',
                    code: r'''
import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/widgets.dart';

/// Builds a themed studio shell with token-driven chrome.
Widget buildStudioShell(BuildContext context) {
  final theme = ConsonaTheme.of(context);
  final colors = theme.colors;
  final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);

  return AnimatedContainer(
    duration: motion.duration,
    curve: motion.curve,
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
      border: theme.border.resolve(ConsonaBorderRole.surfaceEdge, context: context),
      boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Studio Inspector', style: theme.typography.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Long horizontal lines stay scrollable — ConsonaSnippet(maxHeight: 220, tabs: [...veryWideIdentifierChain...])',
          style: theme.typography.caption.copyWith(color: colors.mutedFg),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 12; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('signal[$i] = amplitude * math.sin(phase + $i * 0.15);'),
          ),
      ],
    ),
  );
}
''',
                  ),
                  ConsonaSnippetTab(
                    id: 'swift',
                    label: 'Swift',
                    language: 'swift',
                    code: r'''
import SwiftUI
import ConsonaKit

struct StudioShellView: View {
  @Environment(\.consonaTheme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Studio Inspector")
        .font(.system(.title3, design: .rounded).weight(.semibold))
      Text("Long horizontal lines stay scrollable — ConsonaSnippet(maxHeight: 220, tabs: [...veryWideIdentifierChain...])")
        .foregroundStyle(.secondary)
        .lineLimit(2)

      ForEach(0..<12, id: \.self) { index in
        Text("signal[\(index)] = amplitude * sin(phase + Double(index) * 0.15)")
          .font(.system(.caption, design: .monospaced))
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(theme.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: theme.radius.macro, style: .continuous))
  }
}
''',
                  ),
                  ConsonaSnippetTab(
                    id: 'kotlin',
                    label: 'Kotlin',
                    language: 'kotlin',
                    code: r'''
package consona.studio

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import consona.theme.ConsonaTheme

@Composable
fun StudioShell(modifier: Modifier = Modifier) {
  val theme = ConsonaTheme.current
  val colors = theme.colors

  Column(
    modifier = modifier
      .fillMaxWidth()
      .padding(horizontal = 24.dp, vertical = 16.dp),
  ) {
    Text(text = "Studio Inspector", style = theme.typography.titleMedium)
    Spacer(Modifier.height(8.dp))
    Text(
      text = "Long horizontal lines stay scrollable — ConsonaSnippet(maxHeight: 220, tabs: [...veryWideIdentifierChain...])",
      style = theme.typography.caption,
      color = colors.mutedFg,
    )
    Spacer(Modifier.height(12.dp))
    repeat(12) { index ->
      Text(
        text = "signal[$index] = amplitude * sin(phase + $index * 0.15)",
        style = theme.typography.caption,
      )
      Spacer(Modifier.height(6.dp))
    }
  }
}
''',
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaShowMore(
                expanded: _bioExpanded,
                onExpandedChanged: (v) => setState(() => _bioExpanded = v),
                text:
                    'Consona Mobile is a tactile, token-driven Flutter system — '
                    'hairline borders, spring presses, sensory feedback, and '
                    'optical sizing that stays coherent from phone to desktop. '
                    'Use ShowMore when bios, notes, or changelogs need a soft clamp.',
              ),
              const SizedBox(height: ConsonaSpacing.sm),
              Wrap(
                spacing: ConsonaSpacing.md,
                children: [
                  ConsonaLink(
                    label: 'Read the architecture notes',
                    onTap: () {},
                  ),
                  ConsonaLink(
                    label: 'External docs',
                    external: true,
                    intent: ConsonaIntent.subtle,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaTextArea(
                label: 'Project Summary',
                placeholder: 'Add details or context here...',
                maxLength: 140,
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaTagInput(
                label: 'Component Tags · Wrap',
                layout: ConsonaTagInputLayout.wrap,
                tags: _tagsWrap,
                suggestions: const [
                  'audio',
                  'tokens',
                  'multi-platform',
                  'dark-mode',
                ],
                onChanged: (next) => setState(() => _tagsWrap = next),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaTagInput(
                label: 'Component Tags · Row',
                layout: ConsonaTagInputLayout.row,
                maxVisible: 2,
                tags: _tagsRow,
                suggestions: const [
                  'multi-platform',
                  'dark-mode',
                  'accessibility',
                ],
                onChanged: (next) => setState(() => _tagsRow = next),
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              const ConsonaDivider(label: 'OR UPLOAD ASSETS'),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaFileDropzone(
                title: 'Drop audio stems or preset banks',
                subtitle: 'WAV, FLAC, JSON up to 50 MB',
                files: _uploadItems,
                onBrowse: () {
                  setState(() {
                    _uploadItems = [
                      ..._uploadItems,
                      ConsonaUploadItem(
                        name: 'new_take_${_uploadItems.length + 1}.wav',
                        sizeLabel: '9.2 MB',
                        progress: 1.0,
                      ),
                    ];
                  });
                },
                onRemoveFile: (idx) {
                  setState(() {
                    final next = List<ConsonaUploadItem>.from(_uploadItems)
                      ..removeAt(idx);
                    _uploadItems = next;
                  });
                },
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaPinVerification(
                title: 'Verify Session Code',
                subtitle:
                    'Enter the 6-digit security code sent to alex@consona.dev.',
                resendCooldownSeconds: 15,
                onResend: () {
                  ConsonaToastController.of(context).show(
                    title: 'Code Sent',
                    message: 'A new 6-digit code was sent to alex@consona.dev.',
                    variant: ConsonaToastVariant.info,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fillStatusLabel() {
    switch (_fillType) {
      case ConsonaFillType.solid:
        final rgba = RgbaColor.fromColor(_brandColor);
        return 'solid  ${rgbToHex(rgba.r, rgba.g, rgba.b, rgba.a).toUpperCase()}';
      case ConsonaFillType.gradient:
        return gradientToCss(_brandGradient);
      case ConsonaFillType.image:
        final name = _brandImage.fileName ??
            (_brandImage.url.isEmpty ? 'no image' : 'image');
        return 'image  $name  ·  ${_brandImage.mode.name}'
            '  ·  ${_brandImage.opacity.round()}%';
    }
  }

  Widget _buildColorFillPreview(
    ConsonaThemeData theme,
    ConsonaColors colors,
  ) {
    final radius = theme.radius.resolve(ConsonaRadiusRole.macro);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: 128,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
          ),
          child: switch (_fillType) {
            ConsonaFillType.solid => ColoredBox(color: _brandColor),
            ConsonaFillType.gradient => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _brandGradient.toFlutterGradient(),
                ),
              ),
            ConsonaFillType.image => _brandImage.url.isEmpty
                ? Center(
                    child: Text(
                      'Open picker → Image → set a URL',
                      style: theme.typography.caption
                          .copyWith(color: colors.mutedFg),
                    ),
                  )
                : ConsonaImageFillLayer(
                    config: _brandImage,
                    opacity: (_brandImage.opacity / 100).clamp(0.0, 1.0),
                  ),
          },
        ),
      ),
    );
  }

  Widget _buildPickersTab(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return Column(
      children: [
        ConsonaSection(
          header: 'Date & Time Pickers',
          footer:
              'Month/year surfaces, range selection, dual-wheel time, and combined date-time drawers',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius:
                          theme.radius.resolve(ConsonaRadiusRole.base),
                      border: theme.border.resolve(ConsonaBorderRole.subtle),
                    ),
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selected Date',
                                    style: theme.typography.label),
                                const SizedBox(height: ConsonaSpacing.xxs),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: theme.typography.titleMedium
                                      .copyWith(color: colors.primary),
                                ),
                              ],
                            ),
                            ConsonaButton.subtle(
                              label: 'Open',
                              leading: const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                              ),
                              size: ConsonaOpticalSize.sm,
                              onTap: () async {
                                final picked = await ConsonaDatePicker.show(
                                  context,
                                  initialDate: _selectedDate,
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: ConsonaSpacing.md),
                        ConsonaDatePicker(
                          selectedDate: _selectedDate,
                          onDateChanged: (val) =>
                              setState(() => _selectedDate = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ConsonaSpacing.base),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius:
                          theme.radius.resolve(ConsonaRadiusRole.base),
                      border: theme.border.resolve(ConsonaBorderRole.subtle),
                    ),
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Range',
                                    style: theme.typography.label,
                                  ),
                                  const SizedBox(height: ConsonaSpacing.xxs),
                                  Text(
                                    _formatRange(_rangeStart, _rangeEnd),
                                    style: theme.typography.titleMedium
                                        .copyWith(color: colors.primary),
                                  ),
                                ],
                              ),
                            ),
                            ConsonaButton.subtle(
                              label: 'Open',
                              leading: const Icon(
                                Icons.date_range_rounded,
                                size: 16,
                              ),
                              size: ConsonaOpticalSize.sm,
                              onTap: () async {
                                final result = await ConsonaDatePicker.present(
                                  context,
                                  mode: ConsonaDatePickerMode.range,
                                  rangeStart: _rangeStart,
                                  rangeEnd: _rangeEnd,
                                  title: 'Select Range',
                                );
                                if (result != null) {
                                  setState(() {
                                    _rangeStart = result.start;
                                    _rangeEnd = result.end;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: ConsonaSpacing.md),
                        ConsonaDatePicker(
                          mode: ConsonaDatePickerMode.range,
                          rangeStart: _rangeStart,
                          rangeEnd: _rangeEnd,
                          onRangeChanged: (start, end) => setState(() {
                            _rangeStart = start;
                            _rangeEnd = end;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ConsonaSpacing.base),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius:
                          theme.radius.resolve(ConsonaRadiusRole.base),
                      border: theme.border.resolve(ConsonaBorderRole.subtle),
                    ),
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date & Time',
                                    style: theme.typography.label,
                                  ),
                                  const SizedBox(height: ConsonaSpacing.xxs),
                                  Text(
                                    _formatDateTime(_selectedDateTime),
                                    style: theme.typography.titleMedium
                                        .copyWith(color: colors.primary),
                                  ),
                                ],
                              ),
                            ),
                            ConsonaButton.subtle(
                              label: 'Open',
                              leading: const Icon(
                                Icons.event_available_rounded,
                                size: 16,
                              ),
                              size: ConsonaOpticalSize.sm,
                              onTap: () async {
                                final picked = await ConsonaDateTimePicker.show(
                                  context,
                                  initialDateTime: _selectedDateTime,
                                );
                                if (picked != null) {
                                  setState(() => _selectedDateTime = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: ConsonaSpacing.sm),
                        ConsonaButton.outline(
                          label: 'Open Range + Time',
                          leading: const Icon(Icons.schedule_rounded, size: 16),
                          size: ConsonaOpticalSize.sm,
                          onTap: () async {
                            final result = await ConsonaDateTimePicker.present(
                              context,
                              mode: ConsonaDatePickerMode.range,
                              rangeStart: _rangeStart,
                              rangeEnd: _rangeEnd,
                              title: 'Range & Time',
                            );
                            if (result != null) {
                              setState(() {
                                _rangeStart = result.start;
                                _rangeEnd = result.end;
                                if (result.start != null) {
                                  _selectedDateTime = result.start!;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ConsonaSpacing.base),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius:
                          theme.radius.resolve(ConsonaRadiusRole.base),
                      border: theme.border.resolve(ConsonaBorderRole.subtle),
                    ),
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selected Time',
                                    style: theme.typography.label),
                                const SizedBox(height: ConsonaSpacing.xxs),
                                Text(
                                  _selectedTime.format(context),
                                  style: theme.typography.titleMedium
                                      .copyWith(color: colors.primary),
                                ),
                              ],
                            ),
                            ConsonaButton.subtle(
                              label: 'Open',
                              leading: const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                              ),
                              size: ConsonaOpticalSize.sm,
                              onTap: () async {
                                final picked = await ConsonaTimePicker.show(
                                  context,
                                  initialTime: _selectedTime,
                                );
                                if (picked != null) {
                                  setState(() => _selectedTime = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: ConsonaSpacing.md),
                        SizedBox(
                          height: 180.0,
                          child: ConsonaTimePicker(
                            selectedTime: _selectedTime,
                            onTimeChanged: (val) =>
                                setState(() => _selectedTime = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ConsonaSpacing.lg),
        ConsonaSection(
          header: 'Color',
          footer:
              'Solid · Gradient · Image — Editor/Presets, Soft/Dark/Custom grids, HEX/RGB/CSS/HSL/HSB',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Live fill', style: theme.typography.label),
                  const SizedBox(height: ConsonaSpacing.sm),
                  _buildColorFillPreview(theme, colors),
                  const SizedBox(height: ConsonaSpacing.sm),
                  Text(
                    _fillStatusLabel(),
                    style: theme.typography.caption.copyWith(
                      color: colors.mutedFg,
                      fontFamily: 'Menlo',
                      fontFamilyFallback: const ['Consolas', 'monospace'],
                    ),
                  ),
                  const SizedBox(height: ConsonaSpacing.lg),
                  ConsonaColorPicker(
                    label: 'Brand Fill',
                    value: _brandColor,
                    onChanged: (c) => setState(() => _brandColor = c),
                    defaultFillType: _fillType,
                    onFillTypeChange: (t) => setState(() => _fillType = t),
                    defaultGradient: _brandGradient,
                    onGradientChange: (g) =>
                        setState(() => _brandGradient = g),
                    defaultImageFill: _brandImage,
                    onImageFillChange: (i) => setState(() => _brandImage = i),
                    customSwatches: _customColorSwatches,
                    onCustomSwatchesChange: (s) =>
                        setState(() => _customColorSwatches = s),
                  ),
                  const SizedBox(height: ConsonaSpacing.xl),
                  Text('Solid only', style: theme.typography.label),
                  const SizedBox(height: ConsonaSpacing.xs),
                  Text(
                    'fillTypes locked to solid — still gets Editor | Presets',
                    style: theme.typography.caption
                        .copyWith(color: colors.mutedFg),
                  ),
                  const SizedBox(height: ConsonaSpacing.sm),
                  ConsonaColorPicker(
                    label: 'Accent',
                    value: _solidOnlyColor,
                    onChanged: (c) => setState(() => _solidOnlyColor = c),
                    fillTypes: const [ConsonaFillType.solid],
                    defaultFillType: ConsonaFillType.solid,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ConsonaSpacing.lg),
        ConsonaSection(
          header: 'Cylindrical Wheel Picker',
          footer:
              'Detent haptic ticks with lens magnification and momentum scroll',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                  border: theme.border.resolve(ConsonaBorderRole.subtle),
                ),
                padding: const EdgeInsets.all(ConsonaSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Precision Profile',
                            style: theme.typography.label),
                        Text(
                          _wheelOptions[_wheelIndex],
                          style: theme.typography.caption.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ConsonaSpacing.sm),
                    SizedBox(
                      height: 140.0,
                      child: ConsonaWheelPicker<String>(
                        items: _wheelOptions,
                        initialIndex: _wheelIndex,
                        onSelectedItemChanged: (idx) =>
                            setState(() => _wheelIndex = idx),
                        itemBuilder: (context, item, isSelected) {
                          return Center(
                            child: Text(
                              item,
                              style: theme.typography.body.copyWith(
                                color: isSelected
                                    ? colors.primary
                                    : colors.mutedFg,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsTab(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return ConsonaSection(
      header: 'Steppers, Rating & Selects',
      footer: 'Tabular steppers, touch rating, dropdowns, and country sheet',
      children: [
        Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Workspace Seats', style: theme.typography.body),
                  ConsonaCounter(
                    value: _counter,
                    min: 1,
                    max: 20,
                    onChanged: (val) => setState(() => _counter = val),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const Wrap(
                spacing: ConsonaSpacing.md,
                runSpacing: ConsonaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConsonaStatusDot.online(label: 'Online', ring: true),
                  ConsonaStatusDot.away(label: 'Away'),
                  ConsonaStatusDot.busy(label: 'Busy', pulse: true),
                  ConsonaStatusDot.offline(label: 'Offline'),
                  ConsonaPill(label: 'Beta', intent: ConsonaIntent.primary),
                  ConsonaPill(label: 'v2.4', intent: ConsonaIntent.outline),
                  ConsonaPill(label: 'Stable', intent: ConsonaIntent.success),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaToolbar(
                pill: true,
                scrollable: true,
                density: ConsonaOpticalSize.xs,
                trailing: ConsonaButton.primary(
                  label: 'Export',
                  size: ConsonaOpticalSize.xs,
                  shapeVariant: ConsonaShapeVariant.pill,
                  inflateHitTarget: false,
                  leading: const Icon(Icons.download_rounded, size: 14),
                  onTap: () {},
                ),
                children: [
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.crop_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Crop',
                    onTap: () {},
                  ),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.rotate_left_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Rotate left',
                    onTap: () {},
                  ),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.rotate_right_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Rotate right',
                    onTap: () {},
                  ),
                  const ConsonaToolbarDivider(),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.zoom_out_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Zoom out',
                    onTap: () {},
                  ),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.zoom_in_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Zoom in',
                    onTap: () {},
                  ),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.open_in_full_rounded, size: 16),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Fit',
                    onTap: () {},
                  ),
                  const ConsonaToolbarDivider(),
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    size: ConsonaOpticalSize.sqXs,
                    inflateHitTarget: false,
                    semanticLabel: 'Adjust',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              const ConsonaMeter(
                value: 0.82,
                label: 'Buffer Capacity',
                segments: 14,
              ),
              const SizedBox(height: ConsonaSpacing.base),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Satisfaction Rating', style: theme.typography.body),
                  ConsonaRating(
                    value: _rating,
                    allowHalf: true,
                    onChanged: (val) => setState(() => _rating = val),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Output Gain', style: theme.typography.body),
                      Text(
                        '${(_sliderValue * 100).round()}%',
                        style: theme.typography.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ConsonaSpacing.xs),
                  ConsonaSlider(
                    value: _sliderValue,
                    onChanged: (val) => setState(() => _sliderValue = val),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaRangeSlider(
                label: 'Frequency Bandpass',
                start: _rangeSliderStart,
                end: _rangeSliderEnd,
                onChanged: (s, e) => setState(() {
                  _rangeSliderStart = s;
                  _rangeSliderEnd = e;
                }),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaSegmentedControl<String>(
                fullWidth: true,
                selected: _segmentMode,
                onChanged: (val) => setState(() => _segmentMode = val),
                segments: const [
                  ConsonaSegment(value: 'studio', label: 'Studio'),
                  ConsonaSegment(value: 'live', label: 'Live'),
                  ConsonaSegment(value: 'master', label: 'Master'),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaStepper(
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                steps: const [
                  ConsonaStep(title: 'Capture', isCompleted: true),
                  ConsonaStep(title: 'Process'),
                  ConsonaStep(title: 'Export'),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              ConsonaSelect<String>(
                label: 'Primary Discipline',
                value: _selectedRole,
                items: const [
                  'Designer',
                  'Engineer',
                  'Product Manager',
                  'Researcher'
                ],
                onChanged: (val) => setState(() => _selectedRole = val),
              ),
              const SizedBox(height: ConsonaSpacing.base),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                  border: theme.border.resolve(ConsonaBorderRole.subtle),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: ConsonaSpacing.md,
                  vertical: ConsonaSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(_selectedCountry.flag,
                        style: const TextStyle(fontSize: 22.0)),
                    const SizedBox(width: ConsonaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCountry.name,
                              style: theme.typography.label),
                          Text(
                            _selectedCountry.dialCode,
                            style: theme.typography.caption
                                .copyWith(color: colors.mutedFg),
                          ),
                        ],
                      ),
                    ),
                    ConsonaButton.outline(
                      label: 'Pick Country',
                      size: ConsonaOpticalSize.sm,
                      onTap: () async {
                        final picked = await ConsonaCountryPickerSheet.show(
                          context,
                          current: _selectedCountry,
                        );
                        if (picked != null) {
                          setState(() => _selectedCountry = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlaysTab(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return ConsonaSection(
      header: 'Overlays, Modals & Menus',
      footer:
          'Drawer, Sheet, Modal, toasts & menus — swipe studio tabs to try the pager',
      children: [
        Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: ConsonaSpacing.sm,
                runSpacing: ConsonaSpacing.sm,
                children: [
                  ConsonaButton.subtle(
                    label: 'Action Sheet',
                    leading: const Icon(Icons.more_horiz_rounded, size: 16),
                    size: ConsonaOpticalSize.sm,
                    onTap: () {
                      ConsonaActionSheet.show(
                        context,
                        title: 'Export Stem',
                        message: 'Choose how to share this capture.',
                        actions: const [
                          ConsonaActionSheetItem(
                            id: 'wav',
                            label: 'Download WAV',
                            // Same outline family — sheet forces optical size.
                            icon: Icon(Icons.file_download_outlined),
                          ),
                          ConsonaActionSheetItem(
                            id: 'share',
                            label: 'Share link',
                            icon: Icon(Icons.ios_share_outlined),
                          ),
                          ConsonaActionSheetItem(
                            id: 'delete',
                            label: 'Delete take',
                            destructive: true,
                            icon: Icon(Icons.delete_outline),
                          ),
                        ],
                      );
                    },
                  ),
                  ConsonaButton.subtle(
                    label: 'Drawer',
                    leading:
                        const Icon(Icons.vertical_align_top_rounded, size: 16),
                    size: ConsonaOpticalSize.sm,
                    onTap: () {
                      ConsonaDrawer.show(
                        context,
                        header: const ConsonaDrawerHeader(
                          title: 'Tactile Drawer',
                          subtitle: 'Snap detents · spring drag dismiss',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Partial-height panel from the bottom. Soft blur barrier, multi-snap, no overflow stripes.',
                              style: theme.typography.body
                                  .copyWith(color: colors.mutedFg),
                            ),
                            const SizedBox(height: ConsonaSpacing.lg),
                            ConsonaButton.primary(
                              label: 'Dismiss Drawer',
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ConsonaButton.subtle(
                    label: 'Full Sheet',
                    leading: const Icon(Icons.open_in_full_rounded, size: 16),
                    size: ConsonaOpticalSize.sm,
                    onTap: () {
                      ConsonaSheet.show(
                        context,
                        direction: ConsonaSheetDirection.right,
                        title: 'Full-Screen Sheet',
                        child: Builder(
                          builder: (sheetContext) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Slides in from any edge and covers the entire screen above everything.',
                                  style: theme.typography.body.copyWith(
                                    color: colors.mutedFg,
                                  ),
                                ),
                                const SizedBox(height: ConsonaSpacing.lg),
                                for (final dir in ConsonaSheetDirection.values)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: ConsonaSpacing.xs,
                                    ),
                                    child: ConsonaButton.outline(
                                      label: 'Open from ${dir.name}',
                                      size: ConsonaOpticalSize.sm,
                                      fullWidth: true,
                                      onTap: () {
                                        // Stack on top — do not pop the parent sheet.
                                        ConsonaSheet.show(
                                          sheetContext,
                                          direction: dir,
                                          title: 'From ${dir.name}',
                                          child: Text(
                                            'Entire viewport · drag to dismiss · overflow-safe body.',
                                            style:
                                                theme.typography.body.copyWith(
                                              color: colors.mutedFg,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  ConsonaButton.subtle(
                    label: 'Centered Modal',
                    leading: const Icon(Icons.crop_square_rounded, size: 16),
                    size: ConsonaOpticalSize.sm,
                    onTap: () {
                      ConsonaModal.show(
                        context,
                        title: 'Discard Workspace Changes?',
                        description:
                            'All unsaved canvas layout and node edits will be permanently lost.',
                        confirmLabel: 'Discard',
                        isDestructive: true,
                      );
                    },
                  ),
                  ConsonaPopover(
                    title: 'Quick Inspector',
                    popoverBuilder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Adapts to an anchored floating card on desktop/tablet and a bottom sheet on mobile.',
                          style: theme.typography.caption
                              .copyWith(color: colors.mutedFg),
                        ),
                      ],
                    ),
                    child: IgnorePointer(
                      child: ConsonaButton.subtle(
                        label: 'Popover',
                        leading:
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        size: ConsonaOpticalSize.sm,
                        onTap: () {},
                      ),
                    ),
                  ),
                  ConsonaButton.primary(
                    label: 'Command Palette (⌘K)',
                    leading: const Icon(Icons.terminal_rounded, size: 16),
                    size: ConsonaOpticalSize.sm,
                    onTap: () async {
                      final picked = await ConsonaCommandPalette.show(
                        context,
                        items: [
                          ConsonaCommandItem(
                            id: 'new_scene',
                            title: 'Create New Scene',
                            subtitle: 'Initialize an empty canvas node graph',
                            category: 'Workspace',
                            shortcut: '⌘N',
                            icon: Icon(Icons.add_box_outlined,
                                size: 18, color: colors.primary),
                            onSelected: () =>
                                ConsonaToastController.of(context).show(
                              title: 'Scene Created',
                              message: 'Initialized new canvas node graph.',
                              variant: ConsonaToastVariant.success,
                            ),
                          ),
                          ConsonaCommandItem(
                            id: 'export_tokens',
                            title: 'Export Design Tokens',
                            subtitle: 'Download JSON & Dart token presets',
                            category: 'Workspace',
                            shortcut: '⌘E',
                            icon: Icon(Icons.download_rounded,
                                size: 18, color: colors.primary),
                          ),
                          ConsonaCommandItem(
                            id: 'toggle_theme',
                            title: 'Switch Color Preset',
                            subtitle: 'Cycle Editorial, Brutalist, High-Craft',
                            category: 'Appearance',
                            shortcut: '⌘T',
                            icon: Icon(Icons.palette_outlined,
                                size: 18, color: colors.primary),
                          ),
                        ],
                      );
                      if (picked != null && context.mounted) {
                        ConsonaToastController.of(context).show(
                          title: picked.title,
                          message: 'Executed command "${picked.id}".',
                          variant: ConsonaToastVariant.info,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              Text('Toast Notification Queue', style: theme.typography.label),
              const SizedBox(height: ConsonaSpacing.xs),
              Wrap(
                spacing: ConsonaSpacing.xs,
                runSpacing: ConsonaSpacing.xs,
                children: [
                  ConsonaButton.outline(
                    label: 'Success Toast',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).show(
                      title: 'Saved',
                      message: 'All configuration files synchronized.',
                      variant: ConsonaToastVariant.success,
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Info Toast',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).show(
                      title: 'Indexed',
                      message: 'Analyzed 128 components in workspace.',
                      variant: ConsonaToastVariant.info,
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Warning Toast',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).show(
                      title: 'Memory Alert',
                      message: 'Cache approaching 85% capacity.',
                      variant: ConsonaToastVariant.warning,
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Error Toast',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).show(
                      title: 'Connection Lost',
                      message: 'Telemetry gateway timed out.',
                      variant: ConsonaToastVariant.error,
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Inverted',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).show(
                      title: 'Inverted',
                      message: 'Theme colors flipped for this card.',
                      variant: ConsonaToastVariant.info,
                      inverted: true,
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Custom · Shipped',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).showAs(
                      'shipped',
                      title: 'Shipped',
                      message: 'Your kit left the warehouse.',
                    ),
                  ),
                  ConsonaButton.outline(
                    label: 'Poster Avatar',
                    size: ConsonaOpticalSize.sm,
                    onTap: () => ConsonaToastController.of(context).showAs(
                      'invite',
                      title: 'Maya joined',
                      message: 'Accepted your workspace invite.',
                      poster: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF6366F1),
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      inverted: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),

              // Context Menu Trigger
              GestureDetector(
                onTapDown: (details) {
                  ConsonaContextMenu.show(
                    context,
                    position: details.globalPosition,
                    items: [
                      ConsonaContextMenuItem(
                        id: 'copy',
                        label: 'Copy Specification',
                        icon: Icons.copy_rounded,
                        onTap: () => ConsonaToastController.of(context).show(
                          message: 'Specification copied to clipboard.',
                          variant: ConsonaToastVariant.success,
                        ),
                      ),
                      ConsonaContextMenuItem(
                        id: 'share',
                        label: 'Share Component',
                        icon: Icons.share_rounded,
                        onTap: () {},
                      ),
                      ConsonaContextMenuItem(
                        id: 'delete',
                        label: 'Delete Instance',
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                        onTap: () {},
                      ),
                    ],
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(ConsonaSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                    border: theme.border.resolve(ConsonaBorderRole.subtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tap this tile for Context Menu',
                          style: theme.typography.body),
                      Icon(Icons.more_vert_rounded, color: colors.mutedFg),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.base),

              // Tooltip Trigger
              Center(
                child: ConsonaTooltip(
                  message: 'Long-press triggers spring-scale callout balloon',
                  child: ConsonaChip(
                    label: 'Press & Hold for Tooltip Balloon',
                    leading: Icon(Icons.info_outline_rounded,
                        size: 16, color: colors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurfacesTab(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    const tableRows = <({
      String id,
      String node,
      String region,
      String status,
      int latencyMs
    })>[
      (
        id: 'node-1',
        node: 'synth-edge-01',
        region: 'us-east',
        status: 'Healthy',
        latencyMs: 12
      ),
      (
        id: 'node-2',
        node: 'dsp-worker-04',
        region: 'eu-central',
        status: 'Healthy',
        latencyMs: 28
      ),
      (
        id: 'node-3',
        node: 'render-gpu-02',
        region: 'ap-south',
        status: 'Syncing',
        latencyMs: 64
      ),
      (
        id: 'node-4',
        node: 'vault-store-09',
        region: 'us-west',
        status: 'Healthy',
        latencyMs: 19
      ),
    ];

    return ConsonaSection(
      header: 'Bento Surfaces, Unified Table & Layout',
      footer:
          'Responsive Table + DataTable, SplitView, Timeline, Carousel, Alerts & Breadcrumbs',
      children: [
        Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConsonaBreadcrumbs(
                items: [
                  ConsonaBreadcrumbItem(
                    label: 'Workspace',
                    onTap: () {},
                  ),
                  ConsonaBreadcrumbItem(
                    label: 'Clusters',
                    onTap: () {},
                  ),
                  ConsonaBreadcrumbItem(
                    label: 'Audio DSP',
                    onTap: () {},
                  ),
                  const ConsonaBreadcrumbItem(
                    label: 'Telemetry',
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.base),
              if (_showBanner) ...[
                ConsonaBanner.warning(
                  title: 'Cluster maintenance window',
                  description:
                      'Node restarts start at 02:00 UTC. Pagination below uses ConsonaPagination.',
                  action: ConsonaButton.subtle(
                    label: 'Details',
                    size: ConsonaOpticalSize.xs,
                    onTap: () {},
                  ),
                  onClose: () => setState(() => _showBanner = false),
                ),
                const SizedBox(height: ConsonaSpacing.base),
              ],
              const ConsonaAlert.info(
                title: 'High-Density Grid & Column Resizing',
                description:
                    'Table retains a unified tabular grid with horizontal scrolling and interactive drag handles to resize columns across mobile and desktop.',
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaTable<
                  ({
                    String id,
                    String node,
                    String region,
                    String status,
                    int latencyMs
                  })>(
                title: 'Cluster Nodes (Unified Table)',
                rows: tableRows,
                rowKey: (r) => r.id,
                selectable: true,
                selectedRows: _selectedTableRows,
                onSelectionChanged: (next) =>
                    setState(() => _selectedTableRows = next),
                searchable: true,
                rowsPerPage: 3,
                columns: [
                  ConsonaTableColumn(
                    id: 'node',
                    label: 'Node',
                    flex: 2,
                    sortable: true,
                    valueText: (r) => r.node,
                    cellBuilder: (_, r) => Text(
                      r.node,
                      style: theme.typography.label,
                    ),
                  ),
                  ConsonaTableColumn(
                    id: 'region',
                    label: 'Region',
                    sortable: true,
                    valueText: (r) => r.region,
                    cellBuilder: (_, r) => Text(r.region),
                  ),
                  ConsonaTableColumn(
                    id: 'status',
                    label: 'Status',
                    valueText: (r) => r.status,
                    cellBuilder: (_, r) => ConsonaBadge(label: r.status),
                  ),
                  ConsonaTableColumn(
                    id: 'latency',
                    label: 'Latency',
                    numeric: true,
                    sortable: true,
                    valueText: (r) => '${r.latencyMs}',
                    comparator: (a, b) => a.latencyMs.compareTo(b.latencyMs),
                    cellBuilder: (_, r) => Text('${r.latencyMs} ms'),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              SizedBox(
                height: 200,
                child: ConsonaSplitView(
                  primaryLabel: 'Inspector',
                  secondaryLabel: 'Live Output',
                  primary: Padding(
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Node Inspector', style: theme.typography.label),
                        const SizedBox(height: ConsonaSpacing.xs),
                        Text(
                          'Drag the divider on wide viewports or switch panes via segmented control on mobile.',
                          style: theme.typography.caption
                              .copyWith(color: colors.mutedFg),
                        ),
                      ],
                    ),
                  ),
                  secondary: Padding(
                    padding: const EdgeInsets.all(ConsonaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signal Telemetry', style: theme.typography.label),
                        const SizedBox(height: ConsonaSpacing.xs),
                        const ConsonaProgress(
                          value: 0.78,
                          label: 'DSP Load',
                          showPercentage: true,
                        ),
                        const SizedBox(height: ConsonaSpacing.sm),
                        const ConsonaMeter(
                          value: 0.64,
                          label: 'Headroom',
                          segments: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              Text('Workspace Tree', style: theme.typography.label),
              const SizedBox(height: ConsonaSpacing.sm),
              ConsonaTree(
                selectedId: _treeSelected,
                expandedIds: _treeExpanded,
                onExpandedChanged: (ids) =>
                    setState(() => _treeExpanded = ids),
                onSelected: (node) =>
                    setState(() => _treeSelected = node.id),
                nodes: const [
                  ConsonaTreeNode(
                    id: 'design',
                    label: 'Design System',
                    icon: Icon(Icons.folder_outlined, size: 14),
                    children: [
                      ConsonaTreeNode(id: 'tokens', label: 'Tokens'),
                      ConsonaTreeNode(id: 'motion', label: 'Motion'),
                      ConsonaTreeNode(
                        id: 'components',
                        label: 'Components',
                        children: [
                          ConsonaTreeNode(id: 'inputs', label: 'Inputs'),
                          ConsonaTreeNode(id: 'overlays', label: 'Overlays'),
                        ],
                      ),
                    ],
                  ),
                  ConsonaTreeNode(
                    id: 'audio',
                    label: 'Audio Engine',
                    icon: Icon(Icons.graphic_eq_outlined, size: 14),
                    children: [
                      ConsonaTreeNode(id: 'pcm', label: 'PCM Buffer'),
                      ConsonaTreeNode(id: 'wave', label: 'Waveform'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              Text('Infinite Signal Feed', style: theme.typography.label),
              const SizedBox(height: ConsonaSpacing.sm),
              SizedBox(
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                    border: theme.border.resolve(
                      ConsonaBorderRole.subtle,
                      context: context,
                    ),
                  ),
                  child: ConsonaInfiniteScroll<String>(
                    items: _infiniteItems,
                    hasMore: _infiniteHasMore,
                    loading: _infiniteLoading,
                    onLoadMore: () async {
                      setState(() => _infiniteLoading = true);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 650),
                      );
                      if (!mounted) return;
                      setState(() {
                        final start = _infiniteItems.length;
                        _infiniteItems = [
                          ..._infiniteItems,
                          for (var i = 0; i < 8; i++)
                            'Signal event ${start + i + 1}',
                        ];
                        _infiniteLoading = false;
                        if (_infiniteItems.length >= 40) {
                          _infiniteHasMore = false;
                        }
                      });
                    },
                    itemBuilder: (context, item, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ConsonaSpacing.md,
                          vertical: ConsonaSpacing.sm,
                        ),
                        child: Text(item, style: theme.typography.body),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              const ConsonaTimeline(
                items: [
                  ConsonaTimelineItem(
                    title: 'Token Presets Compiled',
                    subtitle: 'Validated WCAG AA contrast across 5 presets',
                    timestamp: '09:40 AM',
                    intent: ConsonaIntent.success,
                  ),
                  ConsonaTimelineItem(
                    title: 'Audio Engine Initialized',
                    subtitle: 'Low-latency PCM waveform buffer attached',
                    timestamp: '09:42 AM',
                    intent: ConsonaIntent.primary,
                  ),
                  ConsonaTimelineItem(
                    title: 'Awaiting Master Export',
                    subtitle: 'Ready for multi-platform target build',
                    timestamp: 'Pending',
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaCarousel(
                height: 150,
                items: [
                  for (final slide in const [
                    (
                      title: 'Editorial Warmth',
                      desc: 'Paper-inspired surfaces with tactile contrast'
                    ),
                    (
                      title: 'Atmospheric Minimalism',
                      desc: 'Hairline luminance borders and deep dark canvas'
                    ),
                    (
                      title: 'Neo-Brutalist Swiss',
                      desc: 'Crisp structural grids and zero-blur geometry'
                    ),
                  ])
                    Container(
                      padding: const EdgeInsets.all(ConsonaSpacing.base),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.base),
                        border: theme.border.resolve(
                          ConsonaBorderRole.subtle,
                          context: context,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slide.title,
                              style: theme.typography.titleMedium),
                          const SizedBox(height: ConsonaSpacing.xs),
                          Text(
                            slide.desc,
                            style: theme.typography.caption
                                .copyWith(color: colors.mutedFg),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaCard(
                header: ConsonaCard.buildHeader(
                  title: const Text('Autonomous Engine'),
                  subtitle: const Text('Real-time adaptive state dispatch'),
                  trailing: Icon(Icons.bolt_rounded, color: colors.primary),
                ),
                body: ConsonaCard.buildBody(
                  child: Text(
                    'Composes reactive signals, springs, and tactile haptic ticks across all mobile interactions.',
                    style:
                        theme.typography.body.copyWith(color: colors.mutedFg),
                  ),
                ),
                footer: ConsonaCard.buildFooter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ConsonaButton.primary(
                        label: 'Inspect Telemetry',
                        size: ConsonaOpticalSize.sm,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaBentoGrid(
                crossAxisCount: 2,
                tiles: [
                  ConsonaBentoTile(
                    colSpan: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(ConsonaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Adaptive Tokens',
                              style: theme.typography.titleMedium),
                          const SizedBox(height: ConsonaSpacing.xs),
                          Text(
                              '100% token-driven design system with fail-closed stock fallback.',
                              style: theme.typography.caption
                                  .copyWith(color: colors.mutedFg)),
                        ],
                      ),
                    ),
                  ),
                  ConsonaBentoTile(
                    child: Padding(
                      padding: const EdgeInsets.all(ConsonaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.palette_outlined, color: colors.primary),
                          const SizedBox(height: ConsonaSpacing.xs),
                          Text('Presets', style: theme.typography.label),
                        ],
                      ),
                    ),
                  ),
                  ConsonaBentoTile(
                    child: Padding(
                      padding: const EdgeInsets.all(ConsonaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.touch_app_outlined, color: colors.primary),
                          const SizedBox(height: ConsonaSpacing.xs),
                          Text('Feedback', style: theme.typography.label),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              const ConsonaAccordion(
                items: [
                  ConsonaAccordionItem(
                    id: 'c8',
                    title: Text('What is Rule C8 fail-closed?'),
                    content: Text(
                        'Every component functions gracefully without a parent Theme or Shell.'),
                  ),
                  ConsonaAccordionItem(
                    id: 'perf',
                    title: Text('How does motion interpolation work?'),
                    content: Text(
                        'Springs and lerp physics guarantee zero dropped frames on 120Hz displays.'),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.lg),
              ConsonaEmptyState(
                icon: const Icon(Icons.inbox_outlined),
                title: 'No Queued Renders',
                description:
                    'Drop stems or presets here to start batch processing.',
                action: ConsonaButton.subtle(
                  label: 'Import Stems',
                  size: ConsonaOpticalSize.sm,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsonaSection(
          header: 'Player Card',
          footer: 'Poster + slider timeline + transport',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: ConsonaAudioPlayerCard(
                engine: _playerCardEngine,
                showPoster: true,
                posterHeight: 140,
                timeline: ConsonaAudioPlayerTimeline.slider,
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Player Pill',
          footer: 'Isolated engine — independent of the player card',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConsonaAudioPlayerPill(
                  engine: _playerPillEngine,
                  showArtwork: true,
                ),
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Recorder Card',
          footer: 'Isolated capture + preview runtime',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: ConsonaAudioRecorderCard(
                engine: _recorderCardEngine,
                preview: _recorderCardPreview,
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Recorder Pill',
          footer: 'Isolated from the recorder card — own mic + preview',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConsonaAudioRecorderPill(
                  engine: _recorderPillEngine,
                  preview: _recorderPillPreview,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaTab(BuildContext context) {
    final theme = ConsonaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConsonaSection(
          header: 'Inline Video Player',
          footer:
              'Poster, overlay chrome, timeline scrubber, mute — tap to play',
          children: [
            Padding(
              padding: EdgeInsets.all(ConsonaSpacing.base),
              child: ConsonaVideoPlayer(
                uri: 'asset:assets/videos/bee.mp4',
                posterUri:
                    'https://images.unsplash.com/photo-1470114716159-e389f8712fda?auto=format&fit=crop&w=1200&q=80',
                title: 'Pollinator study — field clip',
                looping: true,
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Camera Capture',
          footer:
              'Capture → review → confirm in a bottom card — photo, video, zoom, flip',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConsonaButton.primary(
                    label: 'Open camera',
                    onTap: () async {
                      final captured = await ConsonaCamera.show(context);
                      if (!context.mounted) return;
                      if (captured == null) {
                        ConsonaToastController.of(context).show(
                          title: 'Camera closed',
                          message: 'No media was confirmed.',
                          variant: ConsonaToastVariant.info,
                        );
                        return;
                      }
                      setState(() => _lastCameraCapture = captured);
                      ConsonaToastController.of(context).show(
                        title: captured.isVideo
                            ? 'Video confirmed'
                            : 'Photo confirmed',
                        message: captured.fileName,
                        variant: ConsonaToastVariant.success,
                      );
                    },
                  ),
                  if (_lastCameraCapture case final capture?) ...[
                    const SizedBox(height: ConsonaSpacing.md),
                    Text(
                      'Last capture',
                      style: theme.typography.label.copyWith(
                        color: theme.colors.mutedFg,
                      ),
                    ),
                    const SizedBox(height: ConsonaSpacing.xs),
                    ConsonaListTile(
                      title: capture.fileName,
                      subtitle:
                          '${capture.isVideo ? 'Video' : 'Photo'} · '
                          '${(capture.fileSize / 1024).toStringAsFixed(1)} KB'
                          '${capture.durationMs != null ? ' · ${capture.durationMs! ~/ 1000}s' : ''}',
                      leading: Icon(
                        capture.isVideo
                            ? Icons.videocam_rounded
                            : Icons.photo_camera_rounded,
                        color: theme.colors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Before & After Comparison',
          footer:
              'Draggable hairline slider with grab pill, haptic pulse on 50%, and arrow keys',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: ClipRRect(
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                child: const ConsonaBeforeAfterSlider(
                  before: ConsonaImage(
                    uri:
                        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  after: ConsonaImage(
                    uri:
                        'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  beforeLabel: 'Daylight Raw',
                  afterLabel: 'Aurora Grade',
                ),
              ),
            ),
          ],
        ),
        const ConsonaSection(
          header: 'Adaptive Media Mosaic',
          footer:
              '2×2 mosaic with +N overflow; tap any tile to open the lightbox',
          children: [
            Padding(
              padding: EdgeInsets.all(ConsonaSpacing.base),
              child: ConsonaMediaGrid(
                items: _demoGalleryItems,
                spacing: ConsonaSpacing.sm,
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Document & Attachment Cards',
          footer:
              'Token-derived semantic badges, file size metadata, and upload progress',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Column(
                children: [
                  ConsonaFileCard(
                    item: _demoFileItems[0],
                    statusLabel: 'Ready for Review',
                    onDownload: () => ConsonaToastController.of(context).show(
                      title: 'Downloading Document',
                      message: _demoFileItems[0].name,
                      variant: ConsonaToastVariant.info,
                    ),
                  ),
                  const SizedBox(height: ConsonaSpacing.sm),
                  ConsonaFileCard(
                    item: _demoFileItems[1],
                    progress: 1.0,
                    statusLabel: 'Synced',
                    onRemove: () => ConsonaToastController.of(context).show(
                      title: 'File Removed',
                      message: _demoFileItems[1].name,
                      variant: ConsonaToastVariant.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Dense File Attachments',
          footer:
              'Compact rows for data tables, message attachments, and inspector sidebars',
          children: [
            ConsonaFileRow(
              item: _demoFileItems[2],
              statusLabel: 'Edited 2m ago',
              onTap: () => ConsonaFileViewerModal.show(
                context,
                items: [_demoFileItems[2]],
              ),
              onDownload: () => ConsonaToastController.of(context).show(
                title: 'Downloading Code',
                message: _demoFileItems[2].name,
                variant: ConsonaToastVariant.info,
              ),
            ),
            ConsonaFileRow(
              item: _demoFileItems[3],
              statusLabel: 'Cached',
              onTap: () => ConsonaFileViewerModal.show(
                context,
                items: [_demoFileItems[3]],
              ),
              onDownload: () => ConsonaToastController.of(context).show(
                title: 'Downloading Archive',
                message: _demoFileItems[3].name,
                variant: ConsonaToastVariant.info,
              ),
            ),
          ],
        ),
        ConsonaSection(
          header: 'Full-Screen & Modal Viewers',
          footer:
              'Lightboxes and multi-format viewers with zoom, Esc dismiss, and bottom filmstrip',
          children: [
            Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.base),
              child: Wrap(
                spacing: ConsonaSpacing.sm,
                runSpacing: ConsonaSpacing.sm,
                children: [
                  ConsonaButton.primary(
                    label: 'Open Lightbox (Filmstrip Gallery)',
                    onTap: () => ConsonaLightbox.show(
                      context,
                      items: _demoGalleryItems,
                      moreMenuBuilder: (menuContext, item) {
                        final theme = ConsonaTheme.of(menuContext);
                        final colors = theme.colors;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              item.name,
                              style: theme.typography.caption.copyWith(
                                color: colors.mutedFg,
                              ),
                            ),
                            const SizedBox(height: ConsonaSpacing.sm),
                            ConsonaButton.subtle(
                              label: 'Copy link',
                              size: ConsonaOpticalSize.sm,
                              fullWidth: true,
                              onTap: () => Navigator.of(menuContext).maybePop(),
                            ),
                            const SizedBox(height: ConsonaSpacing.xs),
                            ConsonaButton.subtle(
                              label: 'Open in new tab',
                              size: ConsonaOpticalSize.sm,
                              fullWidth: true,
                              onTap: () => Navigator.of(menuContext).maybePop(),
                            ),
                            const SizedBox(height: ConsonaSpacing.xs),
                            ConsonaButton.danger(
                              label: 'Remove from set',
                              size: ConsonaOpticalSize.sm,
                              fullWidth: true,
                              onTap: () => Navigator.of(menuContext).maybePop(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  ConsonaButton.subtle(
                    label: 'Open Multi-Format File Viewer',
                    onTap: () => ConsonaFileViewerModal.show(
                      context,
                      items: [
                        ..._demoGalleryItems.take(2),
                        ..._demoFileItems,
                      ],
                    ),
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

/// Scroll host for each studio tab page inside [ConsonaSwipeableTabPager].
class _StudioTabScroll extends StatelessWidget {
  const _StudioTabScroll({
    required this.bottomInset,
    required this.child,
  });

  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConsonaScrollArea(
      child: ListView(
        padding: EdgeInsets.only(
          top: ConsonaSpacing.md,
          bottom: bottomInset,
        ),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [child],
      ),
    );
  }
}
