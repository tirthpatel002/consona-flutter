import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double width = 800, double height = 600}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: ConsonaThemeScope(
      theme: ConsonaThemeData.minimal(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Consona Media Suite', () {
    test('ConsonaCameraCaptureResult copyWith preserves fields', () {
      const draft = ConsonaCameraCaptureResult(
        path: '/tmp/clip.mp4',
        kind: ConsonaCapturedMediaKind.video,
        mimeType: 'video/mp4',
        fileName: 'clip.mp4',
        fileSize: 1024,
        durationMs: 5000,
      );
      final muted = draft.copyWith(isMuted: true);
      expect(muted.isMuted, isTrue);
      expect(muted.path, draft.path);
      expect(muted.durationMs, 5000);
    });

    test('ConsonaMediaItem infers extension and media type correctly', () {
      const img = ConsonaMediaItem(id: '1', name: 'photo.webp');
      expect(img.fileExtension, 'webp');
      expect(img.resolvedType, ConsonaMediaType.image);
      expect(img.resolvedType.badgeLabel, 'IMG');
      expect(img.isImage, isTrue);

      const video = ConsonaMediaItem(id: 'v1', name: 'clip.mp4');
      expect(video.resolvedType, ConsonaMediaType.video);
      expect(video.resolvedType.badgeLabel, 'VID');
      expect(video.isVideo, isTrue);

      const pdf = ConsonaMediaItem(id: '2', name: 'invoice.pdf');
      expect(pdf.resolvedType, ConsonaMediaType.document);
      expect(pdf.resolvedType.badgeLabel, 'DOC');

      const code = ConsonaMediaItem(id: '3', name: 'script.dart');
      expect(code.resolvedType, ConsonaMediaType.code);
      expect(code.resolvedType.badgeLabel, 'CODE');

      const archive = ConsonaMediaItem(id: '4', name: 'backup.zip');
      expect(archive.resolvedType, ConsonaMediaType.archive);
      expect(archive.resolvedType.badgeLabel, 'ZIP');

      const audio = ConsonaMediaItem(id: '5', name: 'voice.wav');
      expect(audio.resolvedType, ConsonaMediaType.audio);
      expect(audio.resolvedType.badgeLabel, 'AUD');
    });

    testWidgets('ConsonaImage renders fail-closed fallback on null/empty source',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaImage(
            semanticLabel: 'Avatar image',
          ),
        ),
      );

      expect(find.text('No image source provided'), findsOneWidget);
    });

    testWidgets('ConsonaBeforeAfterSlider handles split dragging and keyboard adjustment',
        (tester) async {
      double? lastSplit;

      await tester.pumpWidget(
        _wrap(
          ConsonaBeforeAfterSlider(
            before: const Text('Original Image'),
            after: const Text('Retouched Image'),
            onSplitChanged: (s) => lastSplit = s,
          ),
          width: 600,
          height: 400,
        ),
      );

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      expect(find.text('Original Image'), findsOneWidget);
      expect(find.text('Retouched Image'), findsOneWidget);

      // Drag the slider handle
      await tester.drag(
        find.byIcon(Icons.swap_horiz_outlined),
        const Offset(60, 0),
      );
      await tester.pump();
      expect(lastSplit, isNotNull);
      expect(lastSplit!, greaterThan(0.5));

      // Keyboard arrow navigation
      await tester.tap(find.byType(ConsonaBeforeAfterSlider));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(lastSplit!, lessThan(0.65));
    });

    testWidgets('ConsonaFileCard and ConsonaFileRow render details and trigger actions',
        (tester) async {
      var downloaded = false;
      var removed = false;
      var tapped = false;

      const file = ConsonaMediaItem(
        id: 'f1',
        name: 'contracts.pdf',
        sizeLabel: '2.4 MB',
      );

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              ConsonaFileCard(
                item: file,
                progress: 0.65,
                statusLabel: 'Uploading...',
                onTap: () => tapped = true,
                onDownload: () => downloaded = true,
                onRemove: () => removed = true,
              ),
              const ConsonaFileRow(
                item: file,
                statusLabel: 'Synced',
              ),
            ],
          ),
        ),
      );

      expect(find.text('contracts.pdf'), findsNWidgets(2));
      expect(find.text('2.4 MB'), findsNWidgets(2));
      expect(find.text('Uploading...'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Download').first);
      await tester.pump();
      expect(downloaded, isTrue);

      await tester.tap(find.byIcon(Icons.close_outlined).first);
      await tester.pump();
      expect(removed, isTrue);

      await tester.tap(find.byType(ConsonaFileCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('ConsonaMediaGrid balances tiles and shows +N overflow badge for 5+ items',
        (tester) async {
      final items = List.generate(
        8,
        (i) => ConsonaMediaItem(
          id: '$i',
          name: 'photo-$i.png',
        ),
      );

      int? tappedIndex;

      await tester.pumpWidget(
        _wrap(
          ConsonaMediaGrid(
            items: items,
            openLightboxOnTap: false,
            onItemTap: (idx) => tappedIndex = idx,
          ),
        ),
      );

      // 2×2 grid: 4 tiles shown, +4 overflow on bottom-right
      expect(find.text('+4'), findsOneWidget);

      await tester.tap(find.text('+4'));
      await tester.pump();
      expect(tappedIndex, 3);
    });

    testWidgets('ConsonaLightbox renders toolbar, counter, and filmstrip gallery',
        (tester) async {
      final items = [
        const ConsonaMediaItem(id: '1', name: 'alpha.png', caption: 'Alpha Frame'),
        const ConsonaMediaItem(id: '2', name: 'beta.png', caption: 'Beta Frame'),
        const ConsonaMediaItem(id: '3', name: 'gamma.png', caption: 'Gamma Frame'),
      ];

      var closed = false;

      await tester.pumpWidget(
        _wrap(
          ConsonaLightbox(
            items: items,
            onClose: () => closed = true,
          ),
          width: 900,
          height: 600,
        ),
      );

      expect(find.text('alpha.png'), findsOneWidget);
      expect(find.text('Alpha Frame'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);

      // Desktop right chevron to advance to next item
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(find.text('beta.png'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);

      // Keyboard left arrow to go back
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('alpha.png'), findsOneWidget);

      // Close button (outlined, same optical size as rotate)
      await tester.tap(find.byIcon(Icons.close_outlined));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('ConsonaLightbox rotates stills and opens more-menu popover',
        (tester) async {
      final items = [
        const ConsonaMediaItem(id: '1', name: 'alpha.png'),
        const ConsonaMediaItem(id: '2', name: 'beta.png'),
      ];
      String? menuItemName;

      await tester.pumpWidget(
        _wrap(
          ConsonaLightbox(
            items: items,
            moreMenuBuilder: (context, item) {
              menuItemName = item.name;
              return Text('Menu for ${item.name}');
            },
          ),
          width: 900,
          height: 600,
        ),
      );

      expect(find.byType(RotatedBox), findsWidgets);
      final before = tester.widgetList<RotatedBox>(find.byType(RotatedBox));
      final activeBefore = before.firstWhere((r) => r.quarterTurns == 0);

      await tester.tap(find.bySemanticsLabel('Rotate'));
      await tester.pump();
      final after = tester.widgetList<RotatedBox>(find.byType(RotatedBox));
      expect(after.any((r) => r.quarterTurns == 1), isTrue);
      expect(activeBefore.quarterTurns, 0);

      expect(find.bySemanticsLabel('More actions'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Menu for alpha.png'), findsOneWidget);
      expect(menuItemName, 'alpha.png');
    });

    testWidgets('ConsonaLightbox plays video items with ConsonaVideoPlayer',
        (tester) async {
      final items = [
        const ConsonaMediaItem(
          id: '1',
          name: 'still.png',
          uri: 'https://example.com/still.png',
        ),
        const ConsonaMediaItem(
          id: '2',
          name: 'clip.mp4',
          caption: 'Field clip',
          uri: 'https://example.com/clip.mp4',
          thumbnailUri: 'https://example.com/poster.jpg',
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          ConsonaLightbox(items: items, initialIndex: 1),
          width: 900,
          height: 600,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('clip.mp4'), findsOneWidget);
      expect(find.text('Field clip'), findsOneWidget);
      expect(find.byType(ConsonaVideoPlayer), findsOneWidget);
      expect(find.bySemanticsLabel('Rotate'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_outlined), findsWidgets);
    });

    testWidgets('ConsonaFileViewerModal renders text file with line count and copy action',
        (tester) async {
      const codeItem = ConsonaMediaItem(
        id: 'c1',
        name: 'config.json',
        sizeLabel: '1.1 KB',
        textContent: '{\n  "version": "1.0.0",\n  "status": "ready"\n}',
      );

      var closed = false;

      await tester.pumpWidget(
        _wrap(
          ConsonaFileViewerModal(
            items: const [codeItem],
            onClose: () => closed = true,
          ),
        ),
      );

      expect(find.text('config.json'), findsOneWidget);
      expect(find.text('1.1 KB'), findsOneWidget);
      expect(find.text('4 lines'), findsOneWidget);
      expect(find.text('Copy Content'), findsOneWidget);

      await tester.tap(find.text('Copy Content'));
      await tester.pump();
      expect(find.text('Copied!'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_outlined));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('ConsonaVideoPlayer renders title and control chrome',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaVideoPlayer(
            uri: 'https://example.com/missing.mp4',
            title: 'Studio field clip',
            showControls: true,
          ),
          width: 640,
          height: 420,
        ),
      );

      // Allow initialize attempt to settle into error / loading chrome.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Studio field clip'), findsOneWidget);
      expect(find.byType(ConsonaVideoPlayer), findsOneWidget);
      // Pre-play: bottom chrome (incl. settings) stays hidden.
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    test('ConsonaVideoStatus exposes expected lifecycle values', () {
      expect(ConsonaVideoStatus.values, contains(ConsonaVideoStatus.idle));
      expect(ConsonaVideoStatus.values, contains(ConsonaVideoStatus.playing));
      expect(ConsonaVideoStatus.values, contains(ConsonaVideoStatus.completed));
      expect(ConsonaVideoStatus.values, contains(ConsonaVideoStatus.error));
    });
  });
}
