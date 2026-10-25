# consona_flutter

Subtle, tactile Flutter UI components with a plugin registry, theme system, and per-surface audio engines.

## Quick start

```dart
import 'package:consona_flutter/consona_flutter.dart';
import 'package:consona_flutter/audio_adapters.dart'; // optional native backends

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsonaProvider(
      theme: ConsonaPresets.minimal(),
      child: Builder(
        builder: (context) {
          final theme = ConsonaTheme.of(context);
          return MaterialApp(
            theme: ThemeData(
              brightness:
                  theme.colors.isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: theme.colors.background,
              extensions: ConsonaProvider.materialExtensionsOf(context),
            ),
            builder: (context, child) => ConsonaToastLayer(
              child: child ?? const SizedBox.shrink(),
            ),
            home: const Home(),
          );
        },
      ),
    );
  }
}
```

Default plugins (`consona.assets`, `consona.feedback`) attach before the first frame when `onAttach` is synchronous. The tree stays gated until the registry is ready — no throwaway `FeedbackEngine`.

## Theme extensions

`ConsonaProvider.materialExtensionsOf(context)` returns `[ConsonaThemeData, …pluginExtensions]`. Pass that list into `ThemeData.extensions`. Plugins contribute extras via `registry.addThemeExtension(...)`.

## Slots

```dart
registry.overrideSlot<void>(
  'shell.header',
  ConsonaSlot.widget(const MyHeader()),
);

// In widgets:
ConsonaSlots.resolve(context, 'shell.header', props, defaultComponent: …);
```

## Toasts

Use `ConsonaToastLayer` in `MaterialApp.builder`. Show toasts with the ambient controller:

```dart
ConsonaToastController.of(context).show(
  message: 'Saved',
  variant: ConsonaToastVariant.success,
);
```

There is no global singleton.

## Feedback

`FeedbackScope` is installed by `ConsonaProvider` when `ConsonaFeedbackPlugin` is attached. `FeedbackScope.of(context)` throws if missing; use `maybeOf` only for optional call sites.

## Audio

Create **one engine per surface** (do not share backends):

```dart
final player = AudioEngine(backend: AudioplayersAudioBackend());
final recorder = AudioRecorderEngine(backend: RecordAudioRecorderBackend());

// Without a backend, engines use silent mocks — fine for tests / previews.
final preview = AudioEngine(); // MockAudioBackend
```

Import adapters from `package:consona_flutter/audio_adapters.dart` (`audioplayers` + `record` package dependencies).

## Navigation

Customize `ConsonaShell` with `header` / `nav` slots, `itemBuilder` on `ConsonaNav`, and `fitContent` / `dense` for bar geometry. Prefer registry slot overrides for app-wide chrome.

## Plugin ids

| Plugin | Id |
|--------|----|
| Assets | `consona.assets` |
| Feedback | `consona.feedback` |
| Overlay | `consona.overlay` |
| Audio | `consona.audio` |

## Overlay engine

`ConsonaOverlayPlugin` registers an [OverlayEngine] and [OverlayScope]. Sheet/modal/drawer hosts register queue items through `showConsonaOverlay` for app-level priority tracking.
