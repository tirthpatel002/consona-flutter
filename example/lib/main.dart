import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';
import 'showcase_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConsonaShowcaseApp());
}

class ConsonaShowcaseApp extends StatefulWidget {
  const ConsonaShowcaseApp({super.key});

  @override
  State<ConsonaShowcaseApp> createState() => _ConsonaShowcaseAppState();
}

class _ConsonaShowcaseAppState extends State<ConsonaShowcaseApp> {
  late final ConsonaThemeController _themeController;
  late final AudioplayersSoundPlayer _soundPlayer;

  @override
  void initState() {
    super.initState();
    _soundPlayer = AudioplayersSoundPlayer();
    _themeController = ConsonaThemeController(
      theme: ConsonaPresets.minimal(),
      themeMode: ConsonaThemeMode.system,
      storage: ConsonaStorageAdapter.memory(),
    );
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConsonaProvider(
      controller: _themeController,
      plugins: [
        ConsonaAssetsPlugin(),
        ConsonaFeedbackPlugin(player: _soundPlayer),
        ConsonaOverlayPlugin(),
      ],
      child: Builder(
        builder: (context) {
          final theme = ConsonaTheme.of(context);
          return MaterialApp(
            title: 'Consona Mobile Showcase',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: theme.colors.isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: theme.colors.background,
              extensions: ConsonaProvider.materialExtensionsOf(context),
            ),
            builder: (context, child) => ConsonaToastLayer(
              child: child ?? const SizedBox.shrink(),
            ),
            home: ShowcaseHome(controller: _themeController),
          );
        },
      ),
    );
  }
}
