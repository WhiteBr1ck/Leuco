// lib/viewmodels/home_viewmodel.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/log_service.dart';
import '../services/settings_service.dart';

class HomeViewModel extends ChangeNotifier {
  String _statusMessage = '请输入链接以开始...';
  String get statusMessage => _statusMessage;

  bool _isFetchingInfo = false;
  bool get isLoading => _isFetchingInfo;

  Map<String, dynamic>? _videoInfo;
  Map<String, dynamic>? get videoInfo => _videoInfo;

  List<Map<String, dynamic>> combinedFormats = [];
  List<Map<String, dynamic>> videoOnlyFormats = [];
  List<Map<String, dynamic>> audioOnlyFormats = [];
  
  List<Map<String, String>> availableSubtitles = [];
  final Set<String> selectedSubtitleLangs = {};

  String? _ytDlpPath;
  final TextEditingController titleController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void toggleSubtitle(String langCode) {
    if (selectedSubtitleLangs.contains(langCode)) {
      selectedSubtitleLangs.remove(langCode);
    } else {
      selectedSubtitleLangs.add(langCode);
    }
    notifyListeners();
  }

  Future<void> fetchVideoInfo(String url, SettingsService settings, LogService logService) async {
    if (url.isEmpty) {
      _statusMessage = '错误：链接不能为空。';
      notifyListeners();
      return;
    }

    logService.addLog('开始获取视频信息: $url');
    _isFetchingInfo = true;
    _videoInfo = null;
    titleController.clear();
    combinedFormats = [];
    videoOnlyFormats = [];
    audioOnlyFormats = [];
    availableSubtitles.clear();
    selectedSubtitleLangs.clear();
    _statusMessage = '正在获取视频信息...';
    notifyListeners();

    try {
      final ytDlpPath = await _getExecutablePath();
      
      final List<String> infoArgs = ['--dump-json'];

      if (settings.enableCustomProxy && settings.proxyUrl.isNotEmpty) {
        infoArgs.addAll(['--proxy', settings.proxyUrl]);
      }
      infoArgs.add(url);
      
      final infoResult = await Process.run(ytDlpPath, infoArgs, stdoutEncoding: systemEncoding, stderrEncoding: systemEncoding);
      if (infoResult.exitCode != 0 || (infoResult.stdout as String).isEmpty) {
        throw Exception('获取视频信息失败，请检查链接或网络。');
      }
      
      _videoInfo = jsonDecode(infoResult.stdout);
      logService.addLog('视频信息获取成功: "${_videoInfo!['title']}"');

      _filterAndCategorizeFormats();
      titleController.text = _videoInfo!['title'];
      _statusMessage = '信息获取成功！正在获取字幕...';
      notifyListeners();

      await _fetchSubtitles(ytDlpPath, url, settings);
      _statusMessage = '信息获取完毕！请选择格式和字幕。';

    } catch (e) {
      _statusMessage = e.toString().replaceFirst("Exception: ", "");
      logService.addLog('获取视频信息失败: $e');
    } finally {
      _isFetchingInfo = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchSubtitles(String ytDlpPath, String url, SettingsService settings) async {
    try {
      final List<String> subsArgs = ['--list-subs'];

      if (settings.enableCustomProxy && settings.proxyUrl.isNotEmpty) {
        subsArgs.addAll(['--proxy', settings.proxyUrl]);
      }
      subsArgs.add(url);

      final result = await Process.run(ytDlpPath, subsArgs, stdoutEncoding: systemEncoding, stderrEncoding: systemEncoding);
      if (result.exitCode != 0) return;

      final stdout = result.stdout as String;
      final listStartIndex = stdout.indexOf('Available subtitles for');
      if (listStartIndex == -1) {
        return;
      }
      
      final lines = stdout.substring(listStartIndex).split('\n');
      final headerIndex = lines.indexWhere((line) => line.trim().startsWith('Language '));
      if (headerIndex == -1) return;

      for (int i = headerIndex + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) break;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 3) continue;

        final langCode = parts[0];
        final langName = parts.sublist(1, parts.length - 1).join(' ');

        if (langCode.isNotEmpty && langName.isNotEmpty) {
          availableSubtitles.add({'code': langCode, 'name': langName});
        }
      }
    } catch (e) {
      print('获取字幕列表时出错: $e');
    }
  }

  void _filterAndCategorizeFormats() {
    if (_videoInfo == null || _videoInfo!['formats'] == null) return;
    final allFormats = (_videoInfo!['formats'] as List).map((f) => f as Map<String, dynamic>);
    combinedFormats = [];
    videoOnlyFormats = [];
    audioOnlyFormats = [];

    for (final f in allFormats) {
        final hasVideo = f['vcodec'] != null && f['vcodec'] != 'none';
        final hasAudio = f['acodec'] != null && f['acodec'] != 'none';
        if (hasVideo && hasAudio) {
            combinedFormats.add(f);
        } else if (hasVideo && !hasAudio) {
            videoOnlyFormats.add(f);
        } else if (!hasVideo && hasAudio) {
            audioOnlyFormats.add(f);
        }
    }

    _sortFormats(combinedFormats);
    _sortFormats(videoOnlyFormats);
    _sortFormats(audioOnlyFormats);
  }
  
  void _sortFormats(List<Map<String, dynamic>> formats) {
    formats.sort((a, b) {
      final int heightA = a['height'] ?? 0;
      final int heightB = b['height'] ?? 0;
      if (heightA != heightB) {
        return heightB.compareTo(heightA);
      }
      
      final num bitrateA = a['tbr'] ?? a['vbr'] ?? a['abr'] ?? 0;
      final num bitrateB = b['tbr'] ?? b['vbr'] ?? b['abr'] ?? 0;
      if (bitrateA != bitrateB) {
        return bitrateB.compareTo(bitrateA);
      }

      final num abrA = a['abr'] ?? 0;
      final num abrB = b['abr'] ?? 0;
      if (abrA != abrB) {
        return abrB.compareTo(abrA);
      }
      
      return 0;
    });
  }

  Future<String> _getExecutablePath() async {
    if (_ytDlpPath != null && await File(_ytDlpPath!).exists()) {
      return _ytDlpPath!;
    }
    final supportDir = await getApplicationSupportDirectory();
    final exePath = path.join(supportDir.path, 'yt-dlp.exe');
    final exeFile = File(exePath);

    if (!await exeFile.exists()) {
      final byteData = await rootBundle.load('assets/bin/yt-dlp.exe');
      final buffer = byteData.buffer.asUint8List();
      await exeFile.writeAsBytes(buffer, flush: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exePath]);
      }
    }
    _ytDlpPath = exePath;
    return exePath;
  }
}