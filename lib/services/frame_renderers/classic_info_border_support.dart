import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as vg;

import '../../models/classic_info_border_settings.dart';
import '../frame_processing_models.dart';

class ClassicInfoBorderLogo {
  const ClassicInfoBorderLogo({
    required this.picture,
    required this.viewportSize,
  });

  final ui.Picture picture;
  final Size viewportSize;

  void dispose() {
    picture.dispose();
  }
}

class ResolvedClassicInfoBorderContent {
  const ResolvedClassicInfoBorderContent({
    required this.title,
    required this.details,
    required this.logoAssetPath,
  });

  final String title;
  final String details;
  final String? logoAssetPath;

  bool get hasText => title.isNotEmpty || details.isNotEmpty;
}

class ClassicInfoBorderMetrics {
  const ClassicInfoBorderMetrics({
    required this.footerHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.titleFontSize,
    required this.detailFontSize,
    required this.logoHeight,
    required this.contentGap,
  });

  final double footerHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double titleFontSize;
  final double detailFontSize;
  final double logoHeight;
  final double contentGap;
}

ResolvedClassicInfoBorderContent resolveClassicInfoBorderContent(
  ClassicInfoBorderSettings settings,
  ExifSnapshot exif,
) {
  final fallbackTitle = settings.manualTitle.trim();
  final fallbackDetails = settings.manualDetails.trim();

  String title;
  String details;
  switch (settings.metadataSource) {
    case ClassicInfoSource.auto:
      title = (exif.model.isNotEmpty ? exif.model : exif.make).trim();
      details = _buildExifDetails(exif);
      if (title.isEmpty) {
        title = fallbackTitle;
      }
      if (details.isEmpty) {
        details = fallbackDetails;
      }
    case ClassicInfoSource.manual:
      title = fallbackTitle;
      details = fallbackDetails;
  }

  return ResolvedClassicInfoBorderContent(
    title: title,
    details: details,
    logoAssetPath: resolveClassicInfoBorderLogoAsset(settings, exif),
  );
}

String? resolveClassicInfoBorderLogoAsset(
  ClassicInfoBorderSettings settings,
  ExifSnapshot exif,
) {
  switch (settings.logo) {
    case CameraLogoOption.none:
      return null;
    case CameraLogoOption.auto:
      final raw = '${exif.make} ${exif.model}'.toLowerCase();
      if (raw.contains('canon')) {
        return CameraLogoOption.canon.assetPath;
      }
      if (raw.contains('sony')) {
        return CameraLogoOption.sony.assetPath;
      }
      if (raw.contains('nikon')) {
        return CameraLogoOption.nikon.assetPath;
      }
      if (raw.contains('leica') || raw.contains('leitz')) {
        return CameraLogoOption.leica.assetPath;
      }
      if (raw.contains('hasselblad')) {
        return CameraLogoOption.hasselblad.assetPath;
      }
      if (raw.contains('dji')) {
        return CameraLogoOption.dji.assetPath;
      }
      return null;
    case CameraLogoOption.canon:
    case CameraLogoOption.sony:
    case CameraLogoOption.nikon:
    case CameraLogoOption.leica:
    case CameraLogoOption.hasselblad:
    case CameraLogoOption.dji:
      return settings.logo.assetPath;
  }
}

Future<ClassicInfoBorderLogo?> loadClassicInfoBorderLogo(
  String? assetPath,
) async {
  if (assetPath == null || assetPath.isEmpty) {
    return null;
  }

  final pictureInfo = await vg.vg.loadPicture(vg.SvgAssetLoader(assetPath), null);
  return ClassicInfoBorderLogo(
    picture: pictureInfo.picture,
    viewportSize: pictureInfo.size,
  );
}

ClassicInfoBorderMetrics calculateClassicInfoBorderMetrics({
  required int targetWidth,
  required int targetHeight,
  required ClassicInfoBorderSettings settings,
}) {
  final titleFontSize = (targetWidth * 0.024 * settings.fontSizeScale).clamp(16.0, 28.0).toDouble();
  final detailFontSize = (titleFontSize * 0.58).clamp(11.0, 16.0).toDouble();
  final horizontalPadding = math.max(24.0, targetWidth * 0.038);
  final verticalPadding = math.max(14.0, targetHeight * 0.016);
  final logoHeight = settings.logo == CameraLogoOption.none
      ? 0.0
      : (titleFontSize * 1.55 * settings.logoScale)
            .clamp(20.0, targetHeight * 0.12)
            .toDouble();
  final contentGap = math.max(12.0, horizontalPadding * 0.32);
  final textHeight = titleFontSize * 1.2 + detailFontSize * 1.35 + 6;
  final contentHeight = math.max(textHeight, logoHeight);
  final footerHeight = (contentHeight + verticalPadding * 2)
      .clamp(72.0, targetHeight * 0.22)
      .toDouble();

  return ClassicInfoBorderMetrics(
    footerHeight: footerHeight,
    horizontalPadding: horizontalPadding,
    verticalPadding: verticalPadding,
    titleFontSize: titleFontSize,
    detailFontSize: detailFontSize,
    logoHeight: logoHeight,
    contentGap: contentGap,
  );
}

void paintClassicInfoBorder({
  required Canvas canvas,
  required LayoutInfo layoutInfo,
  required ClassicInfoBorderSettings settings,
  required ExifSnapshot exif,
  ClassicInfoBorderLogo? logo,
}) {
  if (!settings.enabled || layoutInfo.infoPanelHeight <= 0) {
    return;
  }

  final content = resolveClassicInfoBorderContent(settings, exif);
  final metrics = calculateClassicInfoBorderMetrics(
    targetWidth: layoutInfo.targetWidth,
    targetHeight: layoutInfo.targetHeight,
    settings: settings,
  );
  final footerRect = Rect.fromLTWH(
    0,
    layoutInfo.infoPanelTop.toDouble(),
    layoutInfo.targetWidth.toDouble(),
    layoutInfo.infoPanelHeight.toDouble(),
  );

  final dividerPaint = Paint()
    ..color = const Color(0x1F111111)
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(footerRect.left, footerRect.top),
    Offset(footerRect.right, footerRect.top),
    dividerPaint,
  );

  var textStartX = footerRect.left + metrics.horizontalPadding;
  if (logo != null) {
    final viewport = logo.viewportSize;
    if (viewport.width > 0 && viewport.height > 0) {
      final scale = metrics.logoHeight / viewport.height;
      final logoWidth = viewport.width * scale;
      final logoX = textStartX;
      final logoY = footerRect.center.dy - (metrics.logoHeight / 2);
      canvas.save();
      canvas.translate(logoX, logoY);
      canvas.scale(scale, scale);
      canvas.drawPicture(logo.picture);
      canvas.restore();
      textStartX = logoX + logoWidth + metrics.contentGap;
    }
  }

  if (!content.hasText) {
    return;
  }

  final textWidth = math.max(
    0.0,
    footerRect.right - metrics.horizontalPadding - textStartX,
  );
  if (textWidth <= 1) {
    return;
  }

  final titlePainter = _buildPainter(
    content.title,
    TextStyle(
      color: const Color(0xFF121212),
      fontSize: metrics.titleFontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
    textWidth,
  );
  final detailsPainter = _buildPainter(
    content.details,
    TextStyle(
      color: const Color(0xFF6B6B6B),
      fontSize: metrics.detailFontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.08,
    ),
    textWidth,
  );

  final totalTextHeight =
      titlePainter.height +
      (content.title.isNotEmpty && content.details.isNotEmpty ? 6.0 : 0.0) +
      detailsPainter.height;
  final startY = footerRect.top + ((footerRect.height - totalTextHeight) / 2);
  var cursorY = startY;

  if (content.title.isNotEmpty) {
    titlePainter.paint(canvas, Offset(textStartX, cursorY));
    cursorY += titlePainter.height + 6;
  }
  if (content.details.isNotEmpty) {
    detailsPainter.paint(canvas, Offset(textStartX, cursorY));
  }
}

String _buildExifDetails(ExifSnapshot exif) {
  final infoParts = <String>[
    if (exif.iso.isNotEmpty) 'ISO ${exif.iso}',
    if (exif.fNumber.isNotEmpty) 'f/${exif.fNumber}',
    if (exif.exposureTime.isNotEmpty) '${exif.exposureTime}s',
    if (exif.focalLength.isNotEmpty) '${exif.focalLength}mm',
  ];
  return infoParts.join('   ');
}

TextPainter _buildPainter(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );
  painter.layout(maxWidth: maxWidth);
  return painter;
}
