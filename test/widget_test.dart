import 'dart:typed_data';

import 'package:adaptive_glass_flutter/main.dart';
import 'package:adaptive_glass_flutter/features/editor/adaptive_glass_editor_controller.dart';
import 'package:adaptive_glass_flutter/models/processing_settings.dart';
import 'package:adaptive_glass_flutter/services/adaptive_glass_processor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into the template home page', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('首页'), findsWidgets);
    expect(find.text('快速选择适合照片的边框风格'), findsOneWidget);
  });

  testWidgets('theme can switch to light mode from settings', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('外观'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('外观'))).brightness,
      Brightness.dark,
    );

    await tester.ensureVisible(find.text('浅色模式'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('浅色模式'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('外观'))).brightness,
      Brightness.light,
    );
  });

  test('border-only updates do not rerender preview raster layers', () async {
    final processor = _FakeProcessor();
    final controller = AdaptiveGlassEditorController(processor: processor);
    addTearDown(controller.dispose);

    await controller.loadSource(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      name: 'sample.jpg',
      previewMaxDimension: 100,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(processor.previewCompositeCalls, 1);

    controller.updateSettings(
      controller.settings.copyWith(borderWidth: 18),
      rerender: true,
      previewMaxDimension: 100,
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(processor.previewCompositeCalls, 1);
  });
}

class _FakeProcessor extends AdaptiveGlassProcessor {
  int previewCompositeCalls = 0;

  @override
  Future<ExifSnapshot> readExif(Uint8List sourceBytes) async {
    return const ExifSnapshot();
  }

  @override
  Future<PreviewCompositeOutput> processPreviewComposite(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    int maxDimension = 1600,
  }) async {
    previewCompositeCalls += 1;
    return PreviewCompositeOutput(
      backgroundBytes: Uint8List(0),
      foregroundBytes: Uint8List(0),
      layoutInfo: const LayoutInfo(
        targetWidth: 100,
        targetHeight: 100,
        contentX: 10,
        contentY: 10,
        contentWidth: 80,
        contentHeight: 80,
      ),
      renderScale: 1,
    );
  }
}
