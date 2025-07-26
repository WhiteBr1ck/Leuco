// lib/services/history_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/download_task.dart';

class HistoryService extends ChangeNotifier {
  List<DownloadTask> _history = [];
  List<DownloadTask> get history => _history;

  late File _historyFile;
  bool _isInitialized = false;

  // 初始化服务，找到历史记录文件并读取内容
  Future<void> init() async {
    if (_isInitialized) return;
    final supportDir = await getApplicationSupportDirectory();
    _historyFile = File(path.join(supportDir.path, 'download_history.json'));
    await _loadHistory();
    _isInitialized = true;
  }

  // 从 JSON 文件加载历史记录
  Future<void> _loadHistory() async {
    if (!await _historyFile.exists()) {
      _history = [];
      return;
    }
    try {
      final jsonString = await _historyFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _history = jsonList.map((json) {
        return DownloadTask(
          id: json['id'],
          title: json['title'],
          formatInfo: json['formatInfo'],
          url: json['url'],
          status: DownloadStatus.values[json['status']],
          progress: json['progress'],
          filePath: json['filePath'],
          createdAt: DateTime.parse(json['createdAt']),
        );
      }).toList();
      // 按时间倒序排列
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      print('加载历史记录失败: $e');
      _history = [];
    }
  }
  // 新增的清除历史记录函数
Future<void> clearHistory() async {
  _history = [];
  if (await _historyFile.exists()) {
    await _historyFile.delete();
  }
  notifyListeners();
}

  

  // 添加一条新的历史记录并保存到文件
  Future<void> addToHistory(DownloadTask task) async {
    // 移除可能存在的旧记录
    _history.removeWhere((t) => t.id == task.id);
    _history.insert(0, task);
    
    // 将更新后的列表写入文件
    try {
      final List<Map<String, dynamic>> jsonList = _history.map((t) => {
        'id': t.id,
        'title': t.title,
        'formatInfo': t.formatInfo,
        'url': t.url,
        'status': t.status.index,
        'progress': t.progress,
        'filePath': t.filePath,
        'createdAt': t.createdAt.toIso8601String(),
      }).toList();
      await _historyFile.writeAsString(jsonEncode(jsonList));
      notifyListeners();
    } catch (e) {
      print('保存历史记录失败: $e');
    }
  }
}