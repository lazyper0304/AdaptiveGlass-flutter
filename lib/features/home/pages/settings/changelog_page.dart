import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/update_checker_service.dart';
import '../../../../shared/app_theme.dart';
import '../../widgets/common_home_widgets.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  final UpdateCheckerService _updateService = UpdateCheckerService();
  List<ReleaseInfo> _releases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final releases = await _updateService.getReleaseHistory();
      setState(() {
        _releases = releases;
        _isLoading = false;
      });
    } on UpdateException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildReleaseList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u66f4\u65b0\u65e5\u5fd7',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Adaptive Glass',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading && _errorMessage == null)
            IconButton(
              onPressed: _loadReleases,
              icon: Icon(Icons.refresh_rounded, color: accent),
              style: IconButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: accent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            '\u6b63\u5728\u52a0\u8f7d\u66f4\u65b0\u65e5\u5fd7...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: colors.error.withValues(alpha: 0.62),
            ),
            const SizedBox(height: 16),
            Text(
              '\u52a0\u8f7d\u5931\u8d25',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '\u65e0\u6cd5\u83b7\u53d6\u66f4\u65b0\u4fe1\u606f',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReleases,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('\u91cd\u8bd5'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseList() {
    if (_releases.isEmpty) {
      return _buildEmptyState();
    }

    final colors = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
      physics: const BouncingScrollPhysics(),
      itemCount: _releases.length,
      itemBuilder: (context, index) {
        final release = _releases[index];
        final isLatest = index == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FrostedPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                release.name.isNotEmpty
                                    ? release.name
                                    : release.tagName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.accentColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '\u6700\u65b0',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v${release.version}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isLatest
                                  ? context.accentColor
                                  : colors.onSurface.withValues(alpha: 0.58),
                              fontWeight: isLatest ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (release.formattedDate.isNotEmpty)
                      Text(
                        release.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                  ],
                ),
                if (release.body != null && release.body!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildReleaseNotes(release.body!),
                ],
                if (release.assets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: release.assets.map((asset) {
                      return InkWell(
                        onTap: asset.browserDownloadUrl != null
                            ? () => _downloadAsset(asset)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: 14,
                                color: context.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                asset.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReleaseNotes(String body) {
    final colors = Theme.of(context).colorScheme;
    final lines = body.split('\n');
    final processedLines = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        processedLines.add(const SizedBox(height: 4));
        continue;
      }

      if (trimmed.startsWith('## ')) {
        processedLines.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        processedLines.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u2022 ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.accentColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        processedLines.add(
          Text(
            trimmed,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.72),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: processedLines,
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: colors.onSurface.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 16),
            Text(
              '\u6682\u65e0\u66f4\u65b0\u65e5\u5fd7',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u8bf7\u7a0d\u540e\u518d\u8bd5',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.42),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAsset(ReleaseAsset asset) async {
    if (asset.browserDownloadUrl == null) return;

    try {
      final uri = Uri.parse(asset.browserDownloadUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u65e0\u6cd5\u6253\u5f00: ${asset.name}'),
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
          content: Text('\u4e0b\u8f7d\u5931\u8d25: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
