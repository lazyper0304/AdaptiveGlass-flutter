import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../models/processing_settings.dart';
import '../../services/adaptive_glass_processor.dart';
import 'models/editor_export_payload.dart';
import 'models/export_format_option.dart';

class AdaptiveGlassEditorController extends ChangeNotifier {
  AdaptiveGlassEditorController({AdaptiveGlassProcessor? processor})
    : _processor = processor ?? AdaptiveGlassProcessor();

  final AdaptiveGlassProcessor _processor;

  ProcessingSettings _settings = const ProcessingSettings();
  ExportFormatOption _exportFormat = ExportFormatOption.png;

  Uint8List? _sourceBytes;
  Uint8List? _sourceBytesThumb;
  PreviewCompositeOutput? _previewComposite;
  String? _sourceName;
  String _status = '选择一张图片开始';
  bool _processing = false;

  Timer? _debounceTimer;
  int _currentTaskId = 0;
  int _sourceRevision = 0;
  bool _previewInFlight = false;
  bool _previewQueued = false;
  ExifSnapshot? _sourceExif;
  Future<ExifSnapshot>? _sourceExifFuture;
  int _lastPreviewMaxDimension = 1600;

  ProcessingSettings get settings => _settings;
  ExportFormatOption get exportFormat => _exportFormat;
  PreviewCompositeOutput? get previewComposite => _previewComposite;
  ExifSnapshot get previewExif => _sourceExif ?? const ExifSnapshot();
  String get status => _status;
  bool get processing => _processing;
  String get watermarkText => _settings.watermark.text;
  bool get hasSource => _sourceBytes != null;
  Uint8List? get sourceBytes => _sourceBytes;
  Uint8List? get sourceBytesThumb => _sourceBytesThumb;

  void setStatus(String status, {bool? processing}) {
    _status = status;
    if (processing != null) {
      _processing = processing;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void setExportFormat(ExportFormatOption value) {
    if (_exportFormat == value) {
      return;
    }
    _exportFormat = value;
    notifyListeners();
  }

  Future<void> loadSource({
    required Uint8List bytes,
    required String name,
    required int previewMaxDimension,
  }) async {
    _lastPreviewMaxDimension = previewMaxDimension;
    final sourceRevision = ++_sourceRevision;
    _sourceBytes = bytes;
    _sourceBytesThumb = null;
    _previewComposite = null;
    _sourceName = name;
    _sourceExif = null;
    _sourceExifFuture = null;
    _processing = true;
    _status = '正在生成预览...';
    notifyListeners();

    _warmUpExif(bytes, sourceRevision);
    _generateThumbnail(bytes, sourceRevision);
    _schedulePreviewRender(previewMaxDimension, immediate: true);
  }

  Future<void> _generateThumbnail(Uint8List bytes, int sourceRevision) async {
    try {
      final thumb = await compute(_createThumbnail, bytes);
      if (sourceRevision == _sourceRevision) {
        _sourceBytesThumb = thumb;
        notifyListeners();
      }
    } catch (_) {}
  }

  static Uint8List _createThumbnail(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }
    final thumb = img.copyResize(
      decoded,
      width: 200,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodeJpg(thumb, quality: 70));
  }

  void updateWatermarkText(String text, {required int previewMaxDimension}) {
    _lastPreviewMaxDimension = previewMaxDimension;
    final next = _settings.watermark.copyWith(text: text);
    if (next.text == _settings.watermark.text) {
      return;
    }
    updateSettings(
      _settings.copyWith(watermark: next),
      rerender: true,
      previewMaxDimension: previewMaxDimension,
    );
  }

  void updateSettings(
    ProcessingSettings settings, {
    required bool rerender,
    required int previewMaxDimension,
  }) {
    _lastPreviewMaxDimension = previewMaxDimension;
    _settings = settings;

    if (rerender && hasSource) {
      if (_previewInFlight && _previewComposite == null) {
        _processing = true;
        _status = '正在生成预览...';
      } else {
        _processing = false;
        _status = _previewComposite == null ? '正在生成预览...' : '预览已更新';
      }
    } else if (!hasSource) {
      _status = '设置已更新';
    }

    notifyListeners();
  }

  Future<bool> applyPresetString(
    String raw, {
    required int previewMaxDimension,
  }) async {
    _lastPreviewMaxDimension = previewMaxDimension;
    try {
      final settings = ProcessingSettings.fromPresetString(raw);
      _settings = settings;
      if (hasSource) {
        _processing = false;
        _status = '预设已应用';
      } else {
        _status = '预设已加载';
      }
      notifyListeners();
      return true;
    } catch (error) {
      _processing = false;
      _status = '预设加载失败：$error';
      notifyListeners();
      return false;
    }
  }

  Uint8List buildPresetBytes() {
    return Uint8List.fromList(utf8.encode(_settings.toPresetString()));
  }

  Future<EditorExportPayload?> buildExportPayload() async {
    final sourceBytes = _sourceBytes;
    final sourceName = _sourceName;
    if (sourceBytes == null || sourceName == null) {
      return null;
    }

    final baseName = p.basenameWithoutExtension(sourceName);
    final fileName = '${baseName}_光影边框${_exportFormat.extension}';

    _processing = true;
    _status = '正在导出完整分辨率图片...';
    notifyListeners();

    try {
      final exif =
          _sourceExif ??
          await (_sourceExifFuture ??= _processor.readExif(sourceBytes));
      _sourceExif = exif;
      final output = await _processor.processExport(
        sourceBytes,
        _settings,
        exif: exif,
      );
      final bytes = _processor.encodeForExport(
        output.imageBytes,
        fileName,
        _settings.exportQuality,
      );
      _processing = false;
      _status = '导出已准备好保存';
      notifyListeners();
      return EditorExportPayload(fileName: fileName, bytes: bytes);
    } catch (error) {
      _processing = false;
      _status = '导出失败：$error';
      notifyListeners();
      return null;
    }
  }

  void completeExport({required bool cancelled}) {
    _processing = false;
    _status = cancelled ? '已取消导出' : '导出完成';
    notifyListeners();
  }

  void _warmUpExif(Uint8List sourceBytes, int sourceRevision) {
    final future = _processor.readExif(sourceBytes);
    _sourceExifFuture = future;
    unawaited(
      future.then((exif) {
        if (sourceRevision != _sourceRevision) {
          return;
        }
        _sourceExif = exif;
        if (_settings.watermark.enabled) {
          notifyListeners();
        }
      }),
    );
  }

  void _schedulePreviewRender(
    int previewMaxDimension, {
    bool immediate = false,
  }) {
    if (!hasSource) {
      return;
    }

    _debounceTimer?.cancel();
    final taskId = ++_currentTaskId;
    _processing = true;
    _status = _previewComposite == null ? '正在生成预览...' : '正在刷新预览...';
    notifyListeners();

    _debounceTimer = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 120),
      () => _queuePreviewRender(taskId, previewMaxDimension),
    );
  }

  void _queuePreviewRender(int taskId, int previewMaxDimension) {
    if (_previewInFlight) {
      _previewQueued = true;
      return;
    }
    unawaited(
      _processCurrent(taskId: taskId, previewMaxDimension: previewMaxDimension),
    );
  }

  Future<void> _processCurrent({
    int? taskId,
    required int previewMaxDimension,
  }) async {
    final bytes = _sourceBytes;
    if (bytes == null) {
      return;
    }

    final currentTaskId = taskId ?? _currentTaskId;
    final settings = _settings;
    _previewInFlight = true;

    try {
      final output = await _processor.processPreviewComposite(
        bytes,
        settings,
        maxDimension: previewMaxDimension,
      );
      if (currentTaskId != _currentTaskId || !identical(bytes, _sourceBytes)) {
        return;
      }
      _previewComposite = output;
      _processing = false;
      _status = '预览已更新';
      notifyListeners();
    } catch (error) {
      _processing = false;
      _status = '预览生成失败：$error';
      notifyListeners();
    } finally {
      _previewInFlight = false;
      final shouldQueueNext =
          _sourceBytes != null &&
          (_previewQueued || currentTaskId != _currentTaskId);
      if (shouldQueueNext) {
        _previewQueued = false;
        _debounceTimer?.cancel();
        _queuePreviewRender(_currentTaskId, _lastPreviewMaxDimension);
      }
    }
  }
}
