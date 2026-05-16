import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/adaptive_glass_backdrop.dart';
import 'adaptive_glass_editor_controller.dart';
import 'widgets/editor_preview_card.dart';
import 'widgets/editor_settings_panel.dart';
import 'widgets/editor_status_bar.dart';

class AdaptiveGlassEditorPage extends StatefulWidget {
  const AdaptiveGlassEditorPage({super.key, required this.title});

  final String title;

  @override
  State<AdaptiveGlassEditorPage> createState() =>
      _AdaptiveGlassEditorPageState();
}

class _AdaptiveGlassEditorPageState extends State<AdaptiveGlassEditorPage> {
  late final AdaptiveGlassEditorController _controller;
  late final TextEditingController _watermarkController;

  @override
  void initState() {
    super.initState();
    _controller = AdaptiveGlassEditorController();
    _watermarkController = TextEditingController(
      text: _controller.watermarkText,
    );
    _controller.addListener(_syncWatermarkText);
    _watermarkController.addListener(_handleWatermarkTextChanged);
  }

  @override
  void dispose() {
    _watermarkController.removeListener(_handleWatermarkTextChanged);
    _controller.removeListener(_syncWatermarkText);
    _watermarkController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncWatermarkText() {
    final nextText = _controller.watermarkText;
    if (_watermarkController.text == nextText) {
      return;
    }

    _watermarkController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  void _handleWatermarkTextChanged() {
    _controller.updateWatermarkText(
      _watermarkController.text,
      previewMaxDimension: _previewMaxDimension(context),
    );
  }

  int _previewMaxDimension(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final longestLogicalEdge = math.max(
      mediaQuery.size.width,
      mediaQuery.size.height,
    );
    final desiredEdge = (longestLogicalEdge * mediaQuery.devicePixelRatio)
        .round();
    return desiredEdge.clamp(720, 1600).toInt();
  }

  Future<void> _pickImage() async {
    final previewMaxDimension = _previewMaxDimension(context);
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择图片',
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'bmp',
        'webp',
        'tif',
        'tiff',
      ],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    await _controller.loadSource(
      bytes: file!.bytes!,
      name: file.name,
      previewMaxDimension: previewMaxDimension,
    );
  }

  Future<void> _exportImage() async {
    final payload = await _controller.buildExportPayload();
    if (payload == null) {
      return;
    }

    final target = await FilePicker.saveFile(
      dialogTitle: '导出图片',
      fileName: payload.fileName,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      bytes: payload.bytes,
    );
    if (!mounted) {
      return;
    }

    _controller.completeExport(cancelled: target == null);
  }

  Future<void> _savePreset() async {
    final target = await FilePicker.saveFile(
      dialogTitle: '保存预设',
      fileName: 'adaptive_glass.agp',
      allowedExtensions: const ['agp'],
      bytes: _controller.buildPresetBytes(),
    );
    if (!mounted) {
      return;
    }

    _controller.setStatus(target == null ? '已取消保存' : '预设已保存');
  }

  Future<void> _loadPreset() async {
    final previewMaxDimension = _previewMaxDimension(context);
    final result = await FilePicker.pickFiles(
      dialogTitle: '加载预设',
      type: FileType.custom,
      allowedExtensions: const ['agp'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (bytes == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    await _controller.applyPresetString(
      utf8.decode(bytes),
      previewMaxDimension: previewMaxDimension,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LiquidGlassScope.stack(
      background: const AdaptiveGlassBackdrop(),
      content: Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              appBar: GlassAppBar(
                preferredSize: const Size.fromHeight(58),
                centerTitle: false,
                leading: Tooltip(
                  message: '返回',
                  child: GlassButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onTap: () => context.pop(),
                    width: 44,
                    height: 44,
                    iconSize: 22,
                    label: '返回',
                    quality: GlassQuality.standard,
                  ),
                ),
                title: Hero(
                  tag: 'editor-title-${widget.title}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                actions: [
                  _EditorToolbarButton(
                    tooltip: '导入图片',
                    icon: Icons.file_open_rounded,
                    onTap: _pickImage,
                  ),
                  _EditorToolbarButton(
                    tooltip: '导出图片',
                    icon: Icons.ios_share_rounded,
                    onTap: _exportImage,
                    enabled: _controller.hasSource,
                  ),
                  _EditorToolbarButton(
                    tooltip: '保存预设',
                    icon: Icons.bookmark_add_rounded,
                    onTap: _savePreset,
                  ),
                  _EditorToolbarButton(
                    tooltip: '加载预设',
                    icon: Icons.folder_open_rounded,
                    onTap: _loadPreset,
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1100;
                  final preview = EditorPreviewCard(
                    preview: _controller.previewComposite,
                    settings: _controller.settings,
                    exif: _controller.previewExif,
                    onTap: _pickImage,
                    sourceBytes: _controller.sourceBytes,
                    sourceBytesThumb: _controller.sourceBytesThumb,
                  );
                  final panel = EditorSettingsPanel(
                    settings: _controller.settings,
                    exportFormat: _controller.exportFormat,
                    watermarkController: _watermarkController,
                    onSettingsChanged: (settings) => _controller.updateSettings(
                      settings,
                      rerender: true,
                      previewMaxDimension: _previewMaxDimension(context),
                    ),
                    onExportFormatChanged: _controller.setExportFormat,
                  );

                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 86),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: preview),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(child: panel),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
                    children: [
                      SizedBox(height: 420, child: preview),
                      const SizedBox(height: 18),
                      panel,
                    ],
                  );
                },
              ),
              bottomNavigationBar: EditorStatusBar(
                status: _controller.status,
                processing: _controller.processing,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditorToolbarButton extends StatelessWidget {
  const _EditorToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);

    return Tooltip(
      message: tooltip,
      child: GlassButton(
        icon: Icon(icon),
        onTap: onTap,
        enabled: enabled,
        width: 44,
        height: 44,
        iconSize: 21,
        label: tooltip,
        quality: GlassQuality.standard,
        glowColor: accent.withValues(alpha: 0.34),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
