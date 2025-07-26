import 'dart:io';

enum DownloadStatus { queued, downloading, merging, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String title;
  final String formatInfo;
  final String url;
  DownloadStatus status;
  double progress; // 0.0 to 100.0
  String? filePath;
  DateTime createdAt;
  
  String speed = '';
  String eta = '';
  String totalSize = '';
  String currentStage = '';

  String? downloadDirectory; // 用于存储文件所在的文件夹路径

  DownloadTask({
    required this.id,
    required this.title,
    required this.formatInfo,
    required this.url,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.filePath,
    required this.createdAt,
    this.downloadDirectory, // 在构造函数中加入
  });
}