// lib/pages/update_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/download_manager.dart';
import '../services/log_service.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final String currentVersion = '1.0.0-dev'; // App的版本号
  bool _autoCheckForUpdates = false; // 默认关闭自动检查


  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadManager = context.watch<DownloadManager>();
    final logService = context.read<LogService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('软件更新'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- 应用自身信息 ---
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('当前应用版本'),
                subtitle: Text(currentVersion),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.autorenew),
                title: const Text('启动时自动检查更新'),
                subtitle: const Text('此功能尚未实现'),
                value: _autoCheckForUpdates,
                onChanged: null, // (value) => setState(() => _autoCheckForUpdates = value),
              ),

              const Divider(height: 32),

              // --- 依赖检查 ---
              _buildSectionTitle('依赖组件管理', theme),
              
              ListTile(
                leading: const Icon(Icons.smart_display_outlined),
                title: const Text('yt-dlp 版本'),
                subtitle: downloadManager.isCheckingVersions 
                  ? const Text('正在检查...') 
                  : Text(downloadManager.ytDlpVersion),
                trailing: FilledButton.tonal(
                  onPressed: downloadManager.isUpdatingYtDlp
                    ? null
                    : () async {
                        final resultMessage = await downloadManager.updateYtDlp(logService);
                        _showSnackBar(resultMessage);
                      },
                  child: downloadManager.isUpdatingYtDlp
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('更新'),
                ),
              ),
              
              const SizedBox(height: 8),

              ListTile(
                leading: const Icon(Icons.movie_filter_outlined),
                title: const Text('FFmpeg 版本'),
                subtitle: downloadManager.isCheckingVersions 
                  ? const Text('正在检查...') 
                  : SelectableText(downloadManager.ffmpegVersion, style: theme.textTheme.bodySmall),
              ),

              const SizedBox(height: 24),
              
              // --- 总的检查按钮 ---
              FilledButton.icon(
                onPressed: downloadManager.isCheckingVersions
                  ? null
                  : () => downloadManager.checkDependenciesVersions(logService),
                icon: downloadManager.isCheckingVersions
                  ? Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
                label: const Text('检查依赖版本'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: theme.textTheme.titleLarge),
    );
  }
}