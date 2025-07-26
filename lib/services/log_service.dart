// lib/services/log_service.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class LogService extends ChangeNotifier {
  bool _isDebugging = false;
  bool get isDebugging => _isDebugging;

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void toggleDebugging(bool enabled) {
    _isDebugging = enabled;
    if (_isDebugging) {
      addLog('调试模式已开启。');
    } else {
      addLog('调试模式已关闭。');
    }
    notifyListeners();
  }
  
  void addLog(String message) {
    if (!_isDebugging && !kDebugMode) return; // Release模式下且未开启调试则不记录

    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    _logs.insert(0, '[$timestamp] $message'); // 插入到列表开头，实现倒序
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    addLog('日志已清除。');
    notifyListeners();
  }
}