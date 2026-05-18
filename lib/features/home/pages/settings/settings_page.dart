import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/update_checker_service.dart';
import '../../widgets/common_home_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeModeValue,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeModeValue;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UpdateCheckerService _updateService = UpdateCheckerService();
  bool _isChecking = false;
  String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await AppInfo.getVersion();
    setState(() {
      _currentVersion = version;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final info = await _updateService.checkForUpdates();
      setState(() {
        _isChecking = false;
      });

      if (!mounted) return;

      if (info.hasUpdate) {
        _showUpdateDialog(info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('\u6682\u65e0\u65b0\u7248\u672c'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('\u68c0\u67e5\u66f4\u65b0\u5931\u8d25'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: accent),
            const SizedBox(width: 8),
            const Text('\u53d1\u73b0\u65b0\u7248\u672c'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u5f53\u524d\u7248\u672c: ${info.currentVersion}',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 4),
            Text(
              '\u6700\u65b0\u7248\u672c: ${info.latestVersion}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes!,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.62),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u53d6\u6d88'),
          ),
          if (info.downloadUrl.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openDownloadUrl(info.downloadUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('\u4e0b\u8f7d\u66f4\u65b0'),
            ),
        ],
      ),
    );
  }

  Future<void> _openDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('\u65e0\u6cd5\u6253\u5f00\u4e0b\u8f7d\u94fe\u63a5'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\u6253\u5f00\u94fe\u63a5\u5931\u8d25: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 150),
        children: [
          PageTitleRow(title: '\u8bbe\u7f6e', subtitle: '\u7ba1\u7406\u9884\u8bbe\u548c\u504f\u597d'),
          const SizedBox(height: 28),
          FrostedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u5916\u89c2',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                ThemeModeSelector(
                  themeMode: widget.themeModeValue,
                  onChanged: widget.onThemeModeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FrostedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u5173\u4e8e',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                _buildVersionInfo(),
                const Divider(height: 24),
                _buildUpdateCheckButton(),
                const Divider(height: 24),
                _buildChangelogButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.info_outline_rounded, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adaptive Glass',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\u7248\u672c $_currentVersion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCheckButton() {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);

    return InkWell(
      onTap: _isChecking ? null : _checkForUpdates,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isChecking
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  : Icon(Icons.system_update_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u68c0\u67e5\u66f4\u65b0',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isChecking
                        ? '\u6b63\u5728\u68c0\u67e5...'
                        : '\u4ece GitHub \u83b7\u53d6\u6700\u65b0\u7248\u672c',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isChecking ? null : Icons.chevron_right_rounded,
              color: colors.onSurface.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelogButton() {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);

    return InkWell(
      onTap: () {
        context.push('/changelog');
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.history_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u66f4\u65b0\u65e5\u5fd7',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u67e5\u770b\u6240\u6709\u7248\u672c\u7684\u66f4\u65b0\u5185\u5bb9',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurface.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}
