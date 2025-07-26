// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/history_service.dart';
import '../models/download_task.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 辅助函数，用于打开URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyService = Provider.of<HistoryService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        backgroundColor: theme.colorScheme.primaryContainer,
        // --- 添加清除按钮 ---
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清除所有历史记录',
            onPressed: historyService.history.isEmpty ? null : () {
              // 添加一个确认对话框，防止误触
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认清除'),
                    content: const Text('你确定要清除所有历史记录吗？此操作不可恢复。'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('确认'),
                        onPressed: () {
                          historyService.clearHistory();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: historyService.history.isEmpty
          ? const Center(child: Text('没有历史记录'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyService.history.length,
              itemBuilder: (context, index) {
                final task = historyService.history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  // --- 卡片可以点击 ---
                  child: InkWell(
                    onTap: () => _launchURL(task.url),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: Icon(
                        task.status == DownloadStatus.completed 
                          ? Icons.check_circle
                          : Icons.error,
                        color: task.status == DownloadStatus.completed
                          ? Colors.green
                          : Colors.red,
                      ),
                      title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.formatInfo),
                          const SizedBox(height: 4),
                          Text(
                            '时间: ${DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
    );
  }
}