import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String? releaseNotes;
  final String downloadUrl;
  final DateTime? releaseDate;
  final bool hasUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    this.releaseNotes,
    required this.downloadUrl,
    this.releaseDate,
    required this.hasUpdate,
  });
}

class ReleaseInfo {
  final String tagName;
  final String name;
  final String? body;
  final DateTime? publishedAt;
  final String? htmlUrl;
  final List<ReleaseAsset> assets;

  ReleaseInfo({
    required this.tagName,
    required this.name,
    this.body,
    this.publishedAt,
    this.htmlUrl,
    required this.assets,
  });

  String get version => tagName.replaceFirst(RegExp(r'^v'), '');

  String get formattedDate {
    if (publishedAt == null) return '';
    return '${publishedAt!.year}-${publishedAt!.month.toString().padLeft(2, '0')}-${publishedAt!.day.toString().padLeft(2, '0')}';
  }
}

class ReleaseAsset {
  final String name;
  final String? browserDownloadUrl;

  ReleaseAsset({
    required this.name,
    this.browserDownloadUrl,
  });
}

class UpdateException implements Exception {
  final String message;
  final int? statusCode;

  UpdateException(this.message, {this.statusCode});

  @override
  String toString() => 'UpdateException: $message (status: $statusCode)';
}

class UpdateCheckerService {
  static const String _repositoryOwner = 'lazyper0304';
  static const String _repositoryName = 'AdaptiveGlass-flutter';

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final latestRelease = await _fetchLatestRelease();

      if (latestRelease == null) {
        return UpdateInfo(
          latestVersion: currentVersion,
          currentVersion: currentVersion,
          downloadUrl: '',
          hasUpdate: false,
        );
      }

      final latestVersion = latestRelease['tag_name']?.toString().replaceFirst('v', '') ?? currentVersion;
      final hasUpdate = _compareVersions(latestVersion, currentVersion) > 0;

      String releaseNotes = '';
      if (latestRelease['body'] != null) {
        releaseNotes = latestRelease['body'].toString();
      }

      String downloadUrl = '';
      if (latestRelease['assets'] != null && 
          latestRelease['assets'] is List && 
          (latestRelease['assets'] as List).isNotEmpty) {
        for (var asset in latestRelease['assets']) {
          if (asset['name']?.toString().endsWith('.apk') == true) {
            downloadUrl = asset['browser_download_url']?.toString() ?? '';
            break;
          }
        }
      }

      DateTime? releaseDate;
      if (latestRelease['published_at'] != null) {
        try {
          releaseDate = DateTime.parse(latestRelease['published_at'].toString());
        } catch (_) {}
      }

      return UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        releaseDate: releaseDate,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      final currentVersion = await _getCurrentVersion();
      return UpdateInfo(
        latestVersion: currentVersion,
        currentVersion: currentVersion,
        downloadUrl: '',
        hasUpdate: false,
      );
    }
  }

  Future<String> _getCurrentVersion() async {
    try {
      final version = await AppInfo.getVersion();
      return version;
    } catch (_) {
      return '1.0.0';
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repositoryOwner/$_repositoryName/releases/latest',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ReleaseInfo>> getReleaseHistory() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repositoryOwner/$_repositoryName/releases',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AdaptiveGlass-Flutter-App',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> releasesJson = json.decode(response.body) as List<dynamic>;
        
        return releasesJson.map((release) {
          final Map<String, dynamic> releaseMap = release as Map<String, dynamic>;
          final List<dynamic> assetsList = releaseMap['assets'] as List<dynamic>? ?? [];
          
          return ReleaseInfo(
            tagName: releaseMap['tag_name']?.toString() ?? '',
            name: releaseMap['name']?.toString() ?? releaseMap['tag_name']?.toString() ?? '',
            body: releaseMap['body']?.toString(),
            publishedAt: releaseMap['published_at'] != null
                ? DateTime.tryParse(releaseMap['published_at'].toString())
                : null,
            htmlUrl: releaseMap['html_url']?.toString(),
            assets: assetsList.map((asset) {
              final Map<String, dynamic> assetMap = asset as Map<String, dynamic>;
              return ReleaseAsset(
                name: assetMap['name']?.toString() ?? '',
                browserDownloadUrl: assetMap['browser_download_url']?.toString(),
              );
            }).toList(),
          );
        }).toList();
      } else if (response.statusCode == 404) {
        throw UpdateException('仓库不存在或没有发布版本', statusCode: 404);
      } else if (response.statusCode == 403) {
        throw UpdateException('API请求被限制，请稍后再试', statusCode: 403);
      } else {
        throw UpdateException('无法获取版本信息', statusCode: response.statusCode);
      }
    } on UpdateException {
      rethrow;
    } catch (e) {
      throw UpdateException('网络错误: ${e.toString()}');
    }
  }

  int _compareVersions(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (int i = 0; i < 3; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (latestPart > currentPart) return 1;
      if (latestPart < currentPart) return -1;
    }

    return 0;
  }

  List<int> _parseVersion(String version) {
    final cleaned = version.replaceFirst(RegExp(r'^v'), '').split('+')[0];
    return cleaned.split('.').map((part) {
      final numPart = part.split('-')[0];
      return int.tryParse(numPart) ?? 0;
    }).toList();
  }
}

class AppInfo {
  static Future<String> getVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  static Future<String> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return '1';
    }
  }
}
