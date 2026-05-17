import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../models/processing_settings.dart';
import '../../../../services/frame_processing_models.dart';
import '../../../../services/frame_renderers/classic_frame_renderer.dart';

class ClassicFramePreview extends StatefulWidget {
  const ClassicFramePreview({
    super.key,
    required this.preview,
    required this.settings,
    required this.exif,
    required this.sourceBytes,
    this.thumbBytes,
  });

  final PreviewCompositeOutput? preview;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final Uint8List sourceBytes;
  final Uint8List? thumbBytes;

  @override
  State<ClassicFramePreview> createState() => _ClassicFramePreviewState();
}

class _ClassicFramePreviewState extends State<ClassicFramePreview> {
  ui.Image? _sourceImage;

  @override
  void initState() {
    super.initState();
    _loadSourceImage();
  }

  @override
  void didUpdateWidget(covariant ClassicFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sourceBytes, widget.sourceBytes)) {
      _disposeSourceImage();
      _loadSourceImage();
    }
  }

  Future<void> _loadSourceImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.sourceBytes,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _sourceImage = frame.image;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposeSourceImage();
    super.dispose();
  }

  void _disposeSourceImage() {
    _sourceImage?.dispose();
    _sourceImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final sourceImage = _sourceImage;
    if (sourceImage == null) {
      final thumbBytes = widget.thumbBytes;
      if (thumbBytes != null) {
        return Center(
          child: Image.memory(
            thumbBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      final preview = widget.preview;
      if (preview != null) {
        return Center(
          child: Image.memory(
            preview.compositeBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final layout = calculateClassicLayoutInfo(
      sourceWidth: sourceImage.width,
      sourceHeight: sourceImage.height,
      settings: widget.settings,
    );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: AspectRatio(
        aspectRatio: layout.targetWidth / layout.targetHeight,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ClassicFramePreviewPainter(
              image: sourceImage,
              settings: widget.settings,
              exif: widget.exif,
              layoutInfo: layout,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicFramePreviewPainter extends CustomPainter {
  const _ClassicFramePreviewPainter({
    required this.image,
    required this.settings,
    required this.exif,
    required this.layoutInfo,
  });

  final ui.Image image;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final LayoutInfo layoutInfo;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / layoutInfo.targetWidth;
    final scaleY = size.height / layoutInfo.targetHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    paintClassicFrameToCanvas(
      canvas: canvas,
      image: image,
      layoutInfo: layoutInfo,
      settings: settings,
      exif: exif,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClassicFramePreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.settings != settings ||
        oldDelegate.exif != exif ||
        oldDelegate.layoutInfo != layoutInfo;
  }
}
