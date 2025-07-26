// lib/services/settings_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _seedColor = Colors.orange;
  Color get seedColor => _seedColor;

  bool _enableCustomProxy = false; // 默认不启用自定义代理
  bool get enableCustomProxy => _enableCustomProxy;

  String _proxyUrl = '';
  String get proxyUrl => _proxyUrl;

  bool _askBeforeDownloading = false;
  bool get askBeforeDownloading => _askBeforeDownloading;
  
  String? _defaultDownloadPath;
  String? get defaultDownloadPath => _defaultDownloadPath;

  bool _autoMergeAudio = true;
  bool get autoMergeAudio => _autoMergeAudio;

  double _fontSizeMultiplier = 1.0;
  double get fontSizeMultiplier => _fontSizeMultiplier;

  Future<http.Client> getHttpClient() async {
    // 只有当开关打开，且地址不为空时，才使用代理
    if (enableCustomProxy && proxyUrl.isNotEmpty && Uri.tryParse(proxyUrl) != null) {
      try {
        final uri = Uri.parse(proxyUrl);
        return IOClient(
          HttpClient()
            ..findProxy = (url) {
              return 'PROXY ${uri.host}:${uri.port}';
            }
            ..badCertificateCallback = (cert, host, port) => true,
        );
      } catch (e) {
        print('创建代理客户端失败: $e');
        return http.Client();
      }
    }
    // 其他所有情况，都返回一个普通的、直接连接的客户端
    return http.Client();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    final colorValue = prefs.getInt('seedColor') ?? Colors.orange.value;
    _seedColor = Color(colorValue);

    _enableCustomProxy = prefs.getBool('enableCustomProxy') ?? false;
    _proxyUrl = prefs.getString('proxyUrl') ?? '';
    
    _askBeforeDownloading = prefs.getBool('askBeforeDownloading') ?? false;
    _defaultDownloadPath = prefs.getString('defaultDownloadPath');
    _autoMergeAudio = prefs.getBool('autoMergeAudio') ?? true;

    _fontSizeMultiplier = prefs.getDouble('fontSizeMultiplier') ?? 1.0;

    notifyListeners();
  }
  
  Future<void> updateProxySettings({bool? enableCustomProxy, String? proxyUrl}) async {
    _enableCustomProxy = enableCustomProxy ?? _enableCustomProxy;
    _proxyUrl = proxyUrl ?? _proxyUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableCustomProxy', _enableCustomProxy);
    await prefs.setString('proxyUrl', _proxyUrl);
  }


  Future<void> updateFontSize(double newMultiplier) async {
    _fontSizeMultiplier = newMultiplier;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeMultiplier', newMultiplier);
  }

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    _themeMode = newThemeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', newThemeMode.index);
  }

  Future<void> updateSeedColor(Color newColor) async {
    _seedColor = newColor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', newColor.value);
  }

  Future<void> updateDownloadPath(String? newPath) async {
    _defaultDownloadPath = newPath;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (newPath == null) {
      await prefs.remove('defaultDownloadPath');
    } else {
      await prefs.setString('defaultDownloadPath', newPath);
    }
  }

  Future<void> updateAskBeforeDownloading(bool newValue) async {
    _askBeforeDownloading = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('askBeforeDownloading', newValue);
  }

  Future<void> updateAutoMergeAudio(bool newValue) async {
    _autoMergeAudio = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoMergeAudio', newValue);
  }
}