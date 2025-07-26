// lib/services/download_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/download_task.dart';
import 'history_service.dart';
import 'log_service.dart';
import 'settings_service.dart';

class DownloadManager extends ChangeNotifier {
  final List<DownloadTask> _tasks = [];
  List<DownloadTask> get tasks => _tasks;

  String? _ytDlpPath;
  String? _ffmpegPath;
  
  final Map<String, Process> _runningProcesses = {};

  String _ytDlpVersion = '未知';
  String get ytDlpVersion => _ytDlpVersion;

  String _ffmpegVersion = '未知';
  String get ffmpegVersion => _ffmpegVersion;

  bool _isCheckingVersions = false;
  bool get isCheckingVersions => _isCheckingVersions;

  bool _isUpdatingYtDlp = false;
  bool get isUpdatingYtDlp => _isUpdatingYtDlp;

  Future<void> checkDependenciesVersions(LogService logService) async {
    _isCheckingVersions = true;
    notifyListeners();
    logService.addLog('开始检查依赖版本...');

    try {
      try {
        final ytDlpPath = await _getExecutablePath('yt-dlp.exe');
        final result = await Process.run(ytDlpPath, ['--version']);
        if (result.exitCode == 0 && (result.stdout as String).isNotEmpty) {
          _ytDlpVersion = result.stdout.trim();
          logService.addLog('yt-dlp 版本: $_ytDlpVersion');
        } else {
          _ytDlpVersion = '检查失败';
        }
      } catch (e) {
        _ytDlpVersion = '检查失败';
        logService.addLog('检查 yt-dlp 版本失败: $e');
      }

      try {
        final ffmpegPath = await _getExecutablePath('ffmpeg.exe');
        final result = await Process.run(ffmpegPath, ['-version']);
        if (result.exitCode == 0 && (result.stdout as String).isNotEmpty) {
          _ffmpegVersion = (result.stdout as String).split('\n').first.trim();
          logService.addLog('ffmpeg 版本信息: $_ffmpegVersion');
        } else {
          _ffmpegVersion = '检查失败';
        }
      } catch (e) {
        _ffmpegVersion = '检查失败';
        logService.addLog('检查 ffmpeg 版本失败: $e');
      }
    } finally {
      _isCheckingVersions = false;
      notifyListeners();
    }
  }

  Future<String> updateYtDlp(LogService logService) async {
    _isUpdatingYtDlp = true;
    notifyListeners();
    logService.addLog('开始更新 yt-dlp...');

    try {
      final ytDlpPath = await _getExecutablePath('yt-dlp.exe');
      final result = await Process.run(ytDlpPath, ['-U']);
      
      final output = (result.stdout as String) + (result.stderr as String);

      if (result.exitCode == 0) {
        logService.addLog('yt-dlp 更新成功. 输出: $output');
        await checkDependenciesVersions(logService);
        if (output.contains('is up to date')) {
          return 'yt-dlp 已是最新版本。';
        }
        return 'yt-dlp 更新成功！';
      } else {
        logService.addLog('yt-dlp 更新失败. 输出: $output');
        return 'yt-dlp 更新失败，请查看日志获取详情。';
      }
    } catch (e) {
      logService.addLog('执行 yt-dlp 更新时发生错误: $e');
      return '更新时发生错误。';
    } finally {
      _isUpdatingYtDlp = false;
      notifyListeners();
    }
  }

  void clearAllTasks(LogService logService) {
    logService.addLog('清除所有正在下载的任务。');
    final taskIds = _tasks.map((t) => t.id).toList();
    for (final taskId in taskIds) {
      cancelDownload(taskId, logService);
    }
    notifyListeners();
  }

  void cancelDownload(String taskId, LogService logService) {
    final process = _runningProcesses[taskId];
    if (process != null) {
      process.kill();
      logService.addLog('取消下载任务: $taskId');
    }
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.status = DownloadStatus.cancelled;
      _tasks.removeAt(taskIndex);
    }
    notifyListeners();
  }

  Future<bool> startSubtitleDownload(
    Map<String, dynamic> videoInfo,
    String fileName,
    String langCode,
    SettingsService settings,
    LogService logService,
  ) async {
    logService.addLog('开始下载字幕: $langCode for "${videoInfo['title']}"');
    try {
      final ytDlpPath = await _getExecutablePath('yt-dlp.exe');
      
      String outputPath;
      if (settings.askBeforeDownloading) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) return false;
        outputPath = selectedDirectory;
      } else if (settings.defaultDownloadPath != null) {
        outputPath = settings.defaultDownloadPath!;
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) throw Exception('无法找到下载文件夹。');
        outputPath = downloadsDir.path;
      }
      
      final sanitizedTitle = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final outputTemplate = path.join(outputPath, '$sanitizedTitle.$langCode.%(ext)s');

      final List<String> arguments = [
        '--skip-download',
        '--write-subs',
        '--sub-langs', langCode,
        '--convert-subs', 'srt',
        '-o', outputTemplate,
      ];

      if (settings.enableCustomProxy && settings.proxyUrl.isNotEmpty) {
        arguments.addAll(['--proxy', settings.proxyUrl]);
      }
      
      arguments.add(videoInfo['webpage_url'] as String);

      final process = await Process.run(ytDlpPath, arguments);

      if (process.exitCode == 0) {
        logService.addLog('字幕下载成功: $langCode');
        return true;
      } else {
        logService.addLog('字幕下载失败. Stderr: ${process.stderr}');
        print('字幕下载失败. stderr: ${process.stderr}');
        return false;
      }
    } catch (e) {
      logService.addLog('执行字幕下载时发生错误: $e');
      print('执行字幕下载时发生错误: $e');
      return false;
    }
  }

  Future<void> startDownload(
    Map<String, dynamic> videoInfo, 
    String fileName,
    Map<String, dynamic> selectedFormat, 
    SettingsService settings, 
    HistoryService history,
    Set<String> subtitleLangs,
    LogService logService,
  ) async {
    String formatId = selectedFormat['format_id'];
    String formatInfo = '${selectedFormat['format_note'] ?? selectedFormat['format']} (${selectedFormat['ext']})';
    
    if (settings.autoMergeAudio && selectedFormat['vcodec'] != 'none' && selectedFormat['acodec'] == 'none') {
      final audioFormats = (videoInfo['formats'] as List)
          .map((f) => f as Map<String, dynamic>)
          .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
          .toList();

      if (audioFormats.isNotEmpty) {
        audioFormats.sort((a, b) => (b['abr'] ?? 0).compareTo(a['abr'] ?? 0));
        final bestAudio = audioFormats.first;
        formatId = '${selectedFormat['format_id']}+${bestAudio['format_id']}';
        formatInfo += ' + Best Audio';
      }
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: fileName,
      formatInfo: formatInfo,
      url: videoInfo['webpage_url'],
      createdAt: DateTime.now(),
    );

    _tasks.insert(0, task);
    logService.addLog('创建下载任务: "${task.title}" (ID: ${task.id})');
    notifyListeners();

    _executeDownload(task, formatId, videoInfo, selectedFormat, settings, history, subtitleLangs, logService);
  }

  Future<void> _executeDownload(
    DownloadTask task, 
    String formatId, 
    Map<String, dynamic> videoInfo,
    Map<String, dynamic> selectedFormat,
    SettingsService settings, 
    HistoryService history,
    Set<String> subtitleLangs,
    LogService logService,
  ) async {
    Process? process;
    try {
      logService.addLog('开始执行下载流程: ${task.id}');
      final ytDlpPath = await _getExecutablePath('yt-dlp.exe');
      final ffmpegPath = await _getExecutablePath('ffmpeg.exe');
      
      String outputPath;
      if (settings.askBeforeDownloading) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) {
          task.status = DownloadStatus.cancelled;
          _tasks.removeWhere((t) => t.id == task.id);
          notifyListeners();
          return;
        }
        outputPath = selectedDirectory;
      } else if (settings.defaultDownloadPath != null) {
        outputPath = settings.defaultDownloadPath!;
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) throw Exception('无法找到下载文件夹。');
        outputPath = downloadsDir.path;
      }

      final sanitizedTitle = task.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final videoId = videoInfo['id'];
      final extension = selectedFormat['ext'];

      final finalFileName = '$sanitizedTitle [$videoId].$extension';
      final outputFullPath = path.join(outputPath, finalFileName);
      
      final List<String> arguments = [
        '--progress',
        '--progress-template',
        'mydownload:%(progress._percent_str)s|%(progress._total_bytes_str)s|%(progress._speed_str)s|%(progress._eta_str)s',
        '-f', formatId,
        '-o', outputFullPath,
        '--ffmpeg-location', path.dirname(ffmpegPath),
        '--no-playlist',
        '--no-warnings',
      ];

      if (settings.enableCustomProxy && settings.proxyUrl.isNotEmpty) {
        arguments.addAll(['--proxy', settings.proxyUrl]);
      }
      
      if (subtitleLangs.isNotEmpty) {
        arguments.addAll([
          '--write-subs',
          '--embed-subs',
          '--convert-subs', 'srt',
          '--sub-langs',
          subtitleLangs.join(','),
        ]);
      }
      
      arguments.add(task.url);

      process = await Process.start(ytDlpPath, arguments);
      _runningProcesses[task.id] = process;

      const utf8Decoder = Utf8Decoder(allowMalformed: true);
      process.stdout.transform(utf8Decoder).transform(const LineSplitter()).listen((line) {
        if (line.startsWith('mydownload:')) {
          final parts = line.replaceFirst('mydownload:', '').split('|');
          if (parts.length == 4) {
            final percent = double.tryParse(parts[0].replaceAll('%', '').trim());
            if (percent != null) task.progress = percent;
            task.totalSize = parts[1].trim();
            task.speed = parts[2].trim();
            task.eta = parts[3].trim();
            task.status = DownloadStatus.downloading;
            notifyListeners();
          }
        } else if (line.contains('Merging formats into')) {
          task.status = DownloadStatus.merging;
          logService.addLog('[${task.id}] 正在合并视频格式...');
          notifyListeners();
        } else if (line.contains('Embedding subtitles in')) {
          task.status = DownloadStatus.merging;
          logService.addLog('[${task.id}] 正在嵌入字幕...');
          notifyListeners();
        }
      });

      process.stderr.transform(utf8Decoder).transform(const LineSplitter()).listen((line) {
        print("yt-dlp stderr: $line");
      });

      final exitCode = await process.exitCode;
      
      if (exitCode == 0) {
        task.status = DownloadStatus.completed;
        task.progress = 100.0;
        task.downloadDirectory = outputPath;
        logService.addLog('[${task.id}] 下载成功: "${task.title}"');
      } else {
        if (task.status != DownloadStatus.cancelled) {
          task.status = DownloadStatus.failed;
          logService.addLog('[${task.id}] 下载失败. 退出码: $exitCode');
        }
      }
    } catch (e) {
      task.status = DownloadStatus.failed;
      logService.addLog('[${task.id}] 下载执行时发生严重错误: $e');
      print('下载执行失败: $e');
    } finally {
      if (process != null) {
        _runningProcesses.remove(task.id);
      }
      if (task.status == DownloadStatus.completed || task.status == DownloadStatus.failed) {
        await history.addToHistory(task);
      }
      notifyListeners();
    }
  }

  Future<String> _getExecutablePath(String exeName) async {
    if (exeName == 'yt-dlp.exe' && _ytDlpPath != null) return _ytDlpPath!;
    if (exeName == 'ffmpeg.exe' && _ffmpegPath != null) return _ffmpegPath!;
    final supportDir = await getApplicationSupportDirectory();
    final exePath = path.join(supportDir.path, exeName);
    final exeFile = File(exePath);
    if (!await exeFile.exists()) {
      try {
        final byteData = await rootBundle.load('assets/bin/$exeName');
        await exeFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', exePath]);
        }
      } catch (e) {
        print('无法从assets写入可执行文件 $exeName: $e');
        rethrow;
      }
    }
    if (exeName == 'yt-dlp.exe') _ytDlpPath = exePath;
    else if (exeName == 'ffmpeg.exe') _ffmpegPath = exePath;
    return exePath;
  }
}