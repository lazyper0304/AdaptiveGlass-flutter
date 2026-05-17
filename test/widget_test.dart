import 'dart:typed_data';

import 'package:adaptive_glass_flutter/features/editor/adaptive_glass_editor_controller.dart';
import 'package:adaptive_glass_flutter/features/editor/widgets/tappable_switch_row.dart';
import 'package:adaptive_glass_flutter/features/home/adaptive_glass_home_page.dart';
import 'package:adaptive_glass_flutter/models/frame_template.dart';
import 'package:adaptive_glass_flutter/main.dart';
import 'package:adaptive_glass_flutter/models/processing_settings.dart';
import 'package:adaptive_glass_flutter/services/adaptive_glass_processor.dart';
import 'package:adaptive_glass_flutter/services/frame_processing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    themeMode.value = ThemeMode.dark;
  });

  testWidgets('app boots into the template home page', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.byIcon(Icons.settings_rounded), findsWidgets);
  });

  testWidgets('theme can switch to light mode from settings', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byIcon(Icons.settings_rounded).first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.ensureVisible(find.text('\u6d45\u8272\u6a21\u5f0f'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u6d45\u8272\u6a21\u5f0f'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), ThemeMode.light.name);
  });

  testWidgets('saved theme mode is restored on startup', (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': ThemeMode.light.name,
    });

    await initializeThemeModePreference();
    await tester.pumpWidget(const App());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('switch row toggles when label or switch is tapped', (
    tester,
  ) async {
    var value = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) {
              return TappableSwitchRow(
                label: '启用底部信息边框',
                value: value,
                activeColor: Colors.green,
                onChanged: (nextValue) => setState(() {
                  value = nextValue;
                }),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('启用底部信息边框'));
    await tester.pump();
    await tester.pump();

    expect(value, isTrue);

    final rowRect = tester.getRect(find.byType(TappableSwitchRow));
    await tester.tapAt(Offset(rowRect.right - 16, rowRect.center.dy));
    await tester.pump();
    await tester.pump();

    expect(value, isFalse);
  });

  test('watermark border info border can be disabled', () {
    final controller = AdaptiveGlassEditorController(
      template: FrameTemplate.watermarkBorder,
      processor: _FakeProcessor(),
    );
    addTearDown(controller.dispose);

    expect(controller.settings.classicInfoBorder.enabled, isTrue);

    controller.updateSettings(
      controller.settings.copyWith(
        classicInfoBorder: controller.settings.classicInfoBorder.copyWith(
          enabled: false,
        ),
      ),
      rerender: false,
      previewMaxDimension: 100,
    );

    expect(controller.settings.classicInfoBorder.enabled, isFalse);
  });

  test(
    'watermark-only updates do not rerender preview raster layers',
    () async {
      final processor = _FakeProcessor();
      final controller = AdaptiveGlassEditorController(
        template: FrameTemplate.classic,
        processor: processor,
      );
      addTearDown(controller.dispose);

      await controller.loadSource(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        name: 'sample.jpg',
        previewMaxDimension: 100,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(processor.previewCompositeCalls, 1);

      controller.updateWatermarkText('preview', previewMaxDimension: 100);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(processor.previewCompositeCalls, 1);
    },
  );

  test('border updates do not rerender preview raster layers', () async {
    final processor = _FakeProcessor();
    final controller = AdaptiveGlassEditorController(
      template: FrameTemplate.classic,
      processor: processor,
    );
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

  test('color border preview skips raster composite generation', () async {
    final processor = _FakeProcessor();
    final controller = AdaptiveGlassEditorController(
      template: FrameTemplate.colorBorder,
      processor: processor,
    );
    addTearDown(controller.dispose);

    await controller.loadSource(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      name: 'sample.jpg',
      previewMaxDimension: 100,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(processor.previewCompositeCalls, 0);
    expect(processor.paletteCalls, 1);
  });

  test(
    'classic realtime preview does not keep processing state active',
    () async {
      final processor = _FakeProcessor();
      final controller = AdaptiveGlassEditorController(
        template: FrameTemplate.classic,
        processor: processor,
      );
      addTearDown(controller.dispose);

      await controller.loadSource(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        name: 'sample.jpg',
        previewMaxDimension: 100,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.processing, isFalse);
      expect(controller.status, '预览已更新');
      expect(processor.previewCompositeCalls, 1);
    },
  );
}

class _FakeProcessor extends AdaptiveGlassProcessor {
  int previewCompositeCalls = 0;
  int paletteCalls = 0;

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
      compositeBytes: Uint8List(0),
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

  @override
  Future<List<PaletteSwatch>> extractPalette(
    Uint8List sourceBytes, {
    int count = 5,
  }) async {
    paletteCalls += 1;
    return List<PaletteSwatch>.generate(
      count,
      (index) =>
          PaletteSwatch(red: 20 + index, green: 120 + index, blue: 220 + index),
    );
  }
}
