// lib/pages/downloads_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/download_manager.dart';
import '../models/download_task.dart';
import '../services/log_service.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  Future<void> _onCardTapped(BuildContext context, DownloadTask task) async {
    if (task.status == DownloadStatus.completed && task.downloadDirectory != null) {
      final directoryPath = task.downloadDirectory!;
      final uri = Uri.directory(directoryPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开目录: $directoryPath')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, downloadManager, child) {
        final tasks = downloadManager.tasks;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text('正在下载 (${tasks.length})'),
            backgroundColor: theme.colorScheme.primaryContainer,
            actions: [
              if (tasks.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: '清除所有任务',
                  onPressed: () {
                    final logService = context.read<LogService>();
                    context.read<DownloadManager>().clearAllTasks(logService);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已清除所有下载任务'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
            ],
          ),
          body: tasks.isEmpty
              ? const Center(child: Text('没有正在进行的下载任务'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final bool isDownloading = task.status == DownloadStatus.downloading || task.status == DownloadStatus.merging;
                    final bool isCompleted = task.status == DownloadStatus.completed;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _onCardTapped(context, task),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isDownloading)
                                    IconButton(
                                      icon: const Icon(Icons.cancel),
                                      tooltip: '取消下载',
                                      onPressed: () {
                                        final logService = context.read<LogService>();
                                        context.read<DownloadManager>().cancelDownload(task.id, logService);
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCompleted ? '已完成，点击打开文件所在目录' : task.formatInfo,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isCompleted ? theme.colorScheme.primary : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: task.progress / 100,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${task.progress.toStringAsFixed(1)}% of ${task.totalSize}', style: Theme.of(context).textTheme.labelSmall),
                                  Text(task.speed, style: Theme.of(context).textTheme.labelSmall),
                                  Text('ETA: ${task.eta}', style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '状态: ${_getStatusText(task.status)}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading: return '下载中';
      case DownloadStatus.merging: return '合并音视频...';
      case DownloadStatus.completed: return '已完成';
      case DownloadStatus.failed: return '失败';
      case DownloadStatus.cancelled: return '已取消';
      case DownloadStatus.queued: return '排队中';
    }
  }
}