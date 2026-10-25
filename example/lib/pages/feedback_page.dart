import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  FeedbackProfile _profile = FeedbackProfile.tactile;
  double _volume = 0.8;
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final feedback = FeedbackEngine.of(context);

    // Update active feedback config
    feedback.config = feedback.config.copyWith(
      profile: _profile,
      volume: _volume,
      hapticsEnabled: _hapticsEnabled,
      soundEnabled: _soundEnabled,
    );

    final shell = ConsonaShellScope.maybeOf(context);
    final bottomInset = (shell?.isFloating ?? false) ? 100.0 : 20.0;

    return ListView(
      padding: EdgeInsets.only(top: 20.0, bottom: bottomInset),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConsonaText.hero('Feedback Sandbox'),
              const SizedBox(height: 4.0),
              ConsonaText.caption(
                'Low-latency synthesized micro-sound cues and tactile haptics generated in plain Dart.',
                color: theme.colors.mutedFg,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),

        // 1. Sensory Profile Selector
        ConsonaSection(
          header: 'Sensory Profiles',
          footer: 'Switches the character and intensity curve of every touch cue in the app.',
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaChip(
                    label: 'Tactile (Default)',
                    selected: _profile == FeedbackProfile.tactile,
                    onTap: () => setState(() => _profile = FeedbackProfile.tactile),
                  ),
                  ConsonaChip(
                    label: 'Mechanical',
                    selected: _profile == FeedbackProfile.mechanical,
                    onTap: () => setState(() => _profile = FeedbackProfile.mechanical),
                  ),
                  ConsonaChip(
                    label: 'Subtle',
                    selected: _profile == FeedbackProfile.subtle,
                    onTap: () => setState(() => _profile = FeedbackProfile.subtle),
                  ),
                  ConsonaChip(
                    label: 'Silent (Visuals Only)',
                    selected: _profile == FeedbackProfile.silent,
                    onTap: () => setState(() => _profile = FeedbackProfile.silent),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 2. Synthesized Sound Cues Auditioning
        ConsonaSection(
          header: 'Synthesized Micro-Cues',
          footer: 'Generated in memory via pure-Dart 16-bit PCM WAV rendering (zero bundled audio assets).',
          children: [
            _CueAuditionTile(
              name: 'Tap (Button Press)',
              recipeName: 'tap',
              cueDescription: 'Sine 380 -> 180Hz acoustic mechanical click, 15ms',
              onPlay: () => feedback.trigger(FeedbackEvent.tap),
            ),
            _CueAuditionTile(
              name: 'Toggle On',
              recipeName: 'toggle_on',
              cueDescription: 'Sine 440 -> 660Hz warm rising chord, 25ms',
              onPlay: () => feedback.trigger(FeedbackEvent.toggleOn),
            ),
            _CueAuditionTile(
              name: 'Toggle Off',
              recipeName: 'toggle_off',
              cueDescription: 'Sine 550 -> 370Hz soft falling tone, 23ms',
              onPlay: () => feedback.trigger(FeedbackEvent.toggleOff),
            ),
            _CueAuditionTile(
              name: 'Tick (Stepper/Slider)',
              recipeName: 'tick',
              cueDescription: 'Triangle 600 -> 300Hz subtle crisp snap, 10ms',
              onPlay: () => feedback.trigger(FeedbackEvent.tick),
            ),
            _CueAuditionTile(
              name: 'Pop (Bubble/Select)',
              recipeName: 'pop',
              cueDescription: 'Sine 360 -> 140Hz soft liquid pop, 30ms',
              onPlay: () => feedback.trigger(FeedbackEvent.pop),
            ),
            _CueAuditionTile(
              name: 'Success Chime',
              recipeName: 'success_chime',
              cueDescription: 'Acoustic major third (C5 -> E5), 38ms',
              onPlay: () => feedback.trigger(FeedbackEvent.success),
            ),
            _CueAuditionTile(
              name: 'Error Blip',
              recipeName: 'error_blip',
              cueDescription: 'Triangle 140 -> 90Hz low mechanical buzz, 35ms',
              onPlay: () => feedback.trigger(FeedbackEvent.error),
            ),
            _CueAuditionTile(
              name: 'Swipe (Tab Pager)',
              recipeName: 'swipe',
              cueDescription: 'Soft wind gust — band-limited noise, 360ms',
              showDivider: false,
              onPlay: () => feedback.trigger(FeedbackEvent.swipe),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 3. Haptic Engines & Controls
        ConsonaSection(
          header: 'Master Sensory Switches',
          children: [
            ConsonaListTile(
              title: 'Haptic Feedback',
              subtitle: 'Trigger device taptic / vibration engines',
              trailing: ConsonaSwitch(
                value: _hapticsEnabled,
                onChanged: (val) => setState(() => _hapticsEnabled = val),
              ),
            ),
            ConsonaListTile(
              title: 'Sound Cues',
              subtitle: 'Micro-click synthesizer output',
              trailing: ConsonaSwitch(
                value: _soundEnabled,
                onChanged: (val) => setState(() => _soundEnabled = val),
              ),
            ),
            ConsonaListTile(
              title: 'Volume Level',
              subtitle: '${(_volume * 100).toInt()}%',
              showDivider: false,
              trailing: SizedBox(
                width: 140.0,
                child: ConsonaSlider(
                  value: _volume,
                  onChanged: (val) => setState(() => _volume = val),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CueAuditionTile extends StatelessWidget {
  const _CueAuditionTile({
    required this.name,
    required this.recipeName,
    required this.cueDescription,
    required this.onPlay,
    this.showDivider = true,
  });

  final String name;
  final String recipeName;
  final String cueDescription;
  final VoidCallback onPlay;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);

    // Compute WAV byte size for this recipe
    final recipe = DefaultSoundCues.all[recipeName];
    final byteCount = recipe?.toWav().length ?? 0;

    return ConsonaListTile(
      leading: Container(
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          color: theme.colors.surfaceSecondary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.music_note, size: 18.0),
      ),
      title: name,
      subtitle: '$cueDescription • ${byteCount}B WAV',
      showDivider: showDivider,
      // The tile's default `tap` cue would play on top of the cue being
      // auditioned and mask it, so it is disabled here.
      enableFeedback: false,
      onTap: onPlay,
      trailing: ConsonaButton.subtle(
        label: 'Audition',
        size: ConsonaOpticalSize.xs,
        enableFeedback: false,
        onTap: onPlay,
      ),
    );
  }
}
