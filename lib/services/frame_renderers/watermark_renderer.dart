import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';

void paintWatermark(
  Canvas canvas,
  WatermarkSettings settings,
  ExifSnapshot exif,
  LayoutInfo layoutInfo,
) {
  final templateText =
      settings.text.contains('{') && settings.text.contains('}')
      ? formatWatermarkTemplate(settings.text, exif)
      : settings.text;

  final exifModel = exif.model.isNotEmpty ? exif.model : exif.make;
  final infoParts = <String>[
    if (exif.iso.isNotEmpty) 'ISO${exif.iso}',
    if (exif.fNumber.isNotEmpty) 'f/${exif.fNumber}',
    if (exif.exposureTime.isNotEmpty) '${exif.exposureTime}s',
    if (exif.focalLength.isNotEmpty) '${exif.focalLength}mm',
  ];
  final exifInfo = infoParts.join('  ');

  String modelText = '';
  String infoText = '';

  switch (settings.textMode) {
    case WatermarkModeOption.replace:
      modelText = templateText.isNotEmpty ? templateText : '自定义文本';
      break;
    case WatermarkModeOption.fallback:
      if (exifModel.isNotEmpty) {
        modelText = exifModel;
        infoText = exifInfo;
      } else {
        modelText = templateText.isNotEmpty ? templateText : '无 EXIF 信息';
      }
      break;
    case WatermarkModeOption.append:
      if (exifModel.isNotEmpty) {
        modelText = exifModel;
        infoText = exifInfo;
        if (templateText.isNotEmpty) {
          infoText = infoText.isNotEmpty
              ? '$infoText  |  $templateText'
              : templateText;
        }
      } else {
        modelText = templateText;
      }
      break;
  }

  if (modelText.isEmpty && infoText.isEmpty) {
    return;
  }

  final borderTop = layoutInfo.contentY.toDouble();
  final borderBottom =
      (layoutInfo.targetHeight -
              (layoutInfo.contentY + layoutInfo.contentHeight))
          .toDouble();
  final borderLeft = layoutInfo.contentX.toDouble();
  final borderRight =
      (layoutInfo.targetWidth - (layoutInfo.contentX + layoutInfo.contentWidth))
          .toDouble();

  var baseFontSize = settings.fontSize.toDouble();
  if (settings.autoSize) {
    final isVertical =
        settings.position.storageValue.contains('top') ||
        settings.position.storageValue.contains('bottom');
    if (settings.position == WatermarkPosition.manual) {
      baseFontSize = layoutInfo.targetWidth * 0.03;
    } else if (isVertical) {
      final refBorder = math.max(borderTop, borderBottom);
      baseFontSize = refBorder > 20
          ? refBorder * 0.35
          : layoutInfo.targetWidth * 0.03;
    } else {
      final refBorder = math.max(borderLeft, borderRight);
      if (settings.position.storageValue.contains('left') ||
          settings.position.storageValue.contains('right')) {
        baseFontSize = refBorder > 20
            ? math.min(refBorder * 0.15, layoutInfo.targetHeight * 0.05)
            : layoutInfo.targetWidth * 0.03;
      } else {
        baseFontSize = layoutInfo.targetWidth * 0.03;
      }
    }
    baseFontSize = math.max(12, baseFontSize);
  }

  baseFontSize = math.max(10, baseFontSize * settings.sizeScale);
  final infoFontSize = math.max(10.0, baseFontSize * 0.7);
  final textAlpha = settings.opacity / 100;
  final shadowAlpha = 0.5 * textAlpha;
  final textColor = settings.textColor == MonoColor.white
      ? Colors.white.withValues(alpha: textAlpha)
      : Colors.black.withValues(alpha: textAlpha);
  final shadowColor = settings.textColor == MonoColor.white
      ? Colors.black.withValues(alpha: shadowAlpha)
      : Colors.white.withValues(alpha: shadowAlpha);
  final fontFamily = settings.fontFamily == WatermarkFontFamily.smileySans
      ? 'SmileySans'
      : null;

  final modelPainter = buildWatermarkTextPainter(
    modelText,
    TextStyle(
      color: textColor,
      fontSize: baseFontSize,
      fontWeight: FontWeight.w700,
      fontFamily: fontFamily,
    ),
  );
  final infoPainter = buildWatermarkTextPainter(
    infoText,
    TextStyle(
      color: textColor,
      fontSize: infoFontSize,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
    ),
  );
  final modelShadowPainter = buildWatermarkTextPainter(
    modelText,
    TextStyle(
      color: shadowColor,
      fontSize: baseFontSize,
      fontWeight: FontWeight.w700,
      fontFamily: fontFamily,
    ),
  );
  final infoShadowPainter = buildWatermarkTextPainter(
    infoText,
    TextStyle(
      color: shadowColor,
      fontSize: infoFontSize,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
    ),
  );

  final gap = (modelText.isNotEmpty && infoText.isNotEmpty)
      ? baseFontSize * 0.8
      : 0.0;
  final totalWidth = modelPainter.width + gap + infoPainter.width;
  final maxHeight = math.max(modelPainter.height, infoPainter.height);

  final position = calculateWatermarkPosition(
    settings.position,
    layoutInfo,
    borderTop,
    borderBottom,
    borderLeft,
    borderRight,
    totalWidth,
    maxHeight,
  );
  final x = position.dx + settings.customX.toDouble();
  final y = position.dy + settings.customY.toDouble();

  if (modelText.isNotEmpty) {
    final modelY = y + (maxHeight - modelPainter.height);
    modelShadowPainter.paint(canvas, Offset(x + 1, modelY + 1));
    modelPainter.paint(canvas, Offset(x, modelY));
  }

  if (infoText.isNotEmpty) {
    final infoX = x + modelPainter.width + gap;
    final infoY = y + (maxHeight - infoPainter.height);
    infoShadowPainter.paint(canvas, Offset(infoX + 1, infoY + 1));
    infoPainter.paint(canvas, Offset(infoX, infoY));
  }
}

Offset calculateWatermarkPosition(
  WatermarkPosition position,
  LayoutInfo layoutInfo,
  double borderTop,
  double borderBottom,
  double borderLeft,
  double borderRight,
  double totalWidth,
  double maxHeight,
) {
  double x;
  double y;
  switch (position) {
    case WatermarkPosition.topCenter:
    case WatermarkPosition.topLeft:
    case WatermarkPosition.topRight:
      y = borderTop > 20 ? (borderTop / 2) - (maxHeight / 2) : 20;
      break;
    case WatermarkPosition.bottomCenter:
    case WatermarkPosition.bottomLeft:
    case WatermarkPosition.bottomRight:
      if (borderBottom > 20) {
        final startY = layoutInfo.contentY + layoutInfo.contentHeight;
        y = startY + (borderBottom / 2) - (maxHeight / 2);
      } else {
        y = layoutInfo.targetHeight - maxHeight - 20;
      }
      break;
    case WatermarkPosition.center:
    case WatermarkPosition.centerLeft:
    case WatermarkPosition.centerRight:
    case WatermarkPosition.manual:
      y = (layoutInfo.targetHeight - maxHeight) / 2;
      break;
  }

  switch (position) {
    case WatermarkPosition.topLeft:
    case WatermarkPosition.bottomLeft:
      x = 20;
      break;
    case WatermarkPosition.topRight:
    case WatermarkPosition.bottomRight:
      x = layoutInfo.targetWidth - totalWidth - 20;
      break;
    case WatermarkPosition.centerLeft:
      x = borderLeft > 20 ? (borderLeft / 2) - (totalWidth / 2) : 20;
      break;
    case WatermarkPosition.centerRight:
      if (borderRight > 20) {
        final startX = layoutInfo.contentX + layoutInfo.contentWidth;
        x = startX + (borderRight / 2) - (totalWidth / 2);
      } else {
        x = layoutInfo.targetWidth - totalWidth - 20;
      }
      break;
    case WatermarkPosition.topCenter:
    case WatermarkPosition.bottomCenter:
    case WatermarkPosition.center:
    case WatermarkPosition.manual:
      x = (layoutInfo.targetWidth - totalWidth) / 2;
      break;
  }

  return Offset(x, y);
}

String formatWatermarkTemplate(String template, ExifSnapshot exif) {
  return template
      .replaceAll('{Model}', exif.model)
      .replaceAll('{Make}', exif.make)
      .replaceAll('{ISO}', exif.iso.isNotEmpty ? 'ISO${exif.iso}' : '')
      .replaceAll(
        '{FNumber}',
        exif.fNumber.isNotEmpty ? 'f/${exif.fNumber}' : '',
      )
      .replaceAll(
        '{ExposureTime}',
        exif.exposureTime.isNotEmpty ? '${exif.exposureTime}s' : '',
      )
      .replaceAll(
        '{FocalLength}',
        exif.focalLength.isNotEmpty ? '${exif.focalLength}mm' : '',
      );
}

TextPainter buildWatermarkTextPainter(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  painter.layout();
  return painter;
}
