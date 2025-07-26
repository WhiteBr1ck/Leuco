// lib/pages/home_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../viewmodels/home_viewmodel.dart';
import '../services/download_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _urlController = TextEditingController();
  Uint8List? _thumbnailBytes;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fetchThumbnail(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _thumbnailBytes = null);
      return;
    }
    
    if (mounted) setState(() => _thumbnailBytes = null);
    
    final settings = context.read<SettingsService>();
    final client = await settings.getHttpClient();
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _thumbnailBytes = response.bodyBytes;
          });
        }
      }
    } catch (e) {
      print('加载封面失败: $e');
      if (mounted) {
        _showSnackBar('加载封面图片失败，请检查网络或代理设置。', isError: true);
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final theme = Theme.of(context);
    final isCentered = viewModel.videoInfo == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Stack(
        children: [
          AnimatedAlign(
            alignment: isCentered ? Alignment.center : Alignment.topCenter,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: _buildInputSection(context, viewModel),
          ),
          if (!isCentered)
            Padding(
              padding: const EdgeInsets.only(top: 104), 
              child: AnimatedOpacity(
                opacity: isCentered ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                child: _buildFullResultsLayout(context, viewModel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, HomeViewModel viewModel) {
    final isCentered = viewModel.videoInfo == null;
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: isCentered ? 0 : 8.0,
      ),
      child: SizedBox(
        width: isCentered ? 600 : double.infinity,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isCentered 
              ? _buildCenteredInputContent(context, viewModel, theme) 
              : _buildTopInputContent(context, viewModel),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredInputContent(BuildContext context, HomeViewModel viewModel, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '粘贴视频链接',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            textStyle: theme.textTheme.titleMedium,
          ),
          onPressed: viewModel.isLoading
              ? null
              : () async {
                  final settings = context.read<SettingsService>();
                  final logService = context.read<LogService>();
                  final homeViewModel = context.read<HomeViewModel>();

                  await homeViewModel.fetchVideoInfo(_urlController.text, settings, logService);
                  
                  if (homeViewModel.videoInfo != null) {
                    _fetchThumbnail(homeViewModel.videoInfo!['thumbnail']);
                  } else {
                    _fetchThumbnail(null);
                  }
                },
          icon: viewModel.isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.search),
          label: const Text('获取信息'),
        ),
      ],
    );
  }
  
  Widget _buildTopInputContent(BuildContext context, HomeViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '视频链接',
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: viewModel.isLoading
              ? null
              : () async {
                  final settings = context.read<SettingsService>();
                  final logService = context.read<LogService>();
                  final homeViewModel = context.read<HomeViewModel>();

                  await homeViewModel.fetchVideoInfo(_urlController.text, settings, logService);
                  
                  if (homeViewModel.videoInfo != null) {
                    _fetchThumbnail(homeViewModel.videoInfo!['thumbnail']);
                  } else {
                    _fetchThumbnail(null);
                  }
                },
          icon: viewModel.isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: const Text('获取信息'),
        ),
      ],
    );
  }
  
  Widget _buildFullResultsLayout(BuildContext context, HomeViewModel viewModel) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: _buildResultsSection(viewModel),
          ),
          const SizedBox(height: 8),
          _buildStatusSection(viewModel, theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultsSection(HomeViewModel viewModel) {
    return Card(
      key: ValueKey(viewModel.videoInfo!['id']),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160, height: 90,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.1),
                            child: _thumbnailBytes != null
                                ? Image.memory(_thumbnailBytes!, fit: BoxFit.contain)
                                : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: Material(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _thumbnailBytes == null ? null : () => _saveThumbnail(context, viewModel),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.download, color: _thumbnailBytes == null ? Colors.grey : Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: viewModel.titleController,
                    decoration: const InputDecoration(labelText: '文件名 (可编辑)', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildFormatCategory(context, viewModel, '视频 + 音频', viewModel.combinedFormats),
                  _buildFormatCategory(context, viewModel, '仅视频 (无声)', viewModel.videoOnlyFormats),
                  _buildFormatCategory(context, viewModel, '仅音频', viewModel.audioOnlyFormats),
                  _buildSubtitlesCategory(context, viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlesCategory(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.availableSubtitles.isEmpty) {
      if (viewModel.isLoading) return const ListTile(leading: CircularProgressIndicator(strokeWidth: 2), title: Text("正在加载字幕..."));
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      leading: const Icon(Icons.subtitles_outlined),
      title: Text('可选字幕 (${viewModel.availableSubtitles.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: viewModel.availableSubtitles.map((subtitle) {
        final langCode = subtitle['code']!;
        final langName = subtitle['name']!;
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(langName),
          subtitle: Text(langCode),
          value: viewModel.selectedSubtitleLangs.contains(langCode),
          onChanged: (bool? selected) {
            context.read<HomeViewModel>().toggleSubtitle(langCode);
          },
          secondary: IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '仅下载该字幕文件',
            onPressed: () async {
              final downloadManager = context.read<DownloadManager>();
              final settings = context.read<SettingsService>();
              final logService = context.read<LogService>();
              
              _showSnackBar('开始下载字幕: $langCode...');
              
              final success = await downloadManager.startSubtitleDownload(
                viewModel.videoInfo!,
                viewModel.titleController.text,
                langCode,
                settings,
                logService,
              );
              if (success) {
                _showSnackBar('字幕 "$langCode" 下载成功！');
              } else {
                _showSnackBar('字幕 "$langCode" 下载失败。', isError: true);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatCategory(BuildContext context, HomeViewModel viewModel, String title, List<Map<String, dynamic>> formats) {
    if (formats.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text('$title (${formats.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: title.contains('视频 + 音频'),
      children: formats.map((format) {
        String fileSizeDisplay;
        num? fileSize = format['filesize'];
        bool isApprox = false;
        if (fileSize == null) {
          fileSize = format['filesize_approx'];
          isApprox = true;
        }
        if (fileSize != null) {
          final prefix = isApprox ? '~' : '';
          fileSizeDisplay = '$prefix${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB';
        } else {
          fileSizeDisplay = '未知大小';
        }
        
        String vcodec = (format['vcodec'] as String?)?.toLowerCase() ?? 'none';
        if (vcodec.startsWith('av01')) { vcodec = 'AV1'; }
        else if (vcodec.startsWith('vp9') || vcodec.startsWith('vp09')) { vcodec = 'VP9'; }
        else if (vcodec.startsWith('avc1')) { vcodec = 'H.24 (AVC)'; }

        final dynamicRange = format['dynamic_range'] ?? 'SDR';
        final titleText = '[ID: ${format['format_id']}] ${format['format_note'] ?? ''} (${format['ext']})'.trim();
        
        final List<String> subtitleParts = [];
        if (format['acodec'] != 'none' && format['vcodec'] != 'none') {
            subtitleParts.add(format['resolution'] ?? '');
            subtitleParts.add(vcodec);
            if (format['tbr'] != null) subtitleParts.add('${(format['tbr'] / 1000).toStringAsFixed(1)} Mbps');
            subtitleParts.add(dynamicRange);
            subtitleParts.add(fileSizeDisplay);
        } else if (format['vcodec'] != 'none') {
            subtitleParts.add(format['resolution'] ?? '');
            subtitleParts.add(vcodec);
            if (format['vbr'] != null) subtitleParts.add('${(format['vbr'] / 1000).toStringAsFixed(1)} Mbps');
            subtitleParts.add(dynamicRange);
            subtitleParts.add(fileSizeDisplay);
        } else {
            if (format['abr'] != null) subtitleParts.add('${(format['abr']).toStringAsFixed(0)} kbps');
            subtitleParts.add(format['acodec'] ?? 'unknown audio');
            subtitleParts.add(fileSizeDisplay);
        }

        final String subtitle = subtitleParts.where((s) => s.isNotEmpty).join(' - ');

        return ListTile(
          leading: Icon(
            format['acodec'] == 'none' ? Icons.videocam_off_outlined : 
            format['vcodec'] == 'none' ? Icons.audiotrack_outlined : 
            Icons.videocam_outlined
          ),
          title: Text(titleText),
          subtitle: Text(subtitle),
          trailing: FilledButton.tonal(
            onPressed: () {
              final downloadManager = context.read<DownloadManager>();
              final settings = context.read<SettingsService>();
              final history = context.read<HistoryService>();
              final logService = context.read<LogService>();

              downloadManager.startDownload(
                viewModel.videoInfo!,
                viewModel.titleController.text,
                format,
                settings,
                history,
                viewModel.selectedSubtitleLangs,
                logService,
              );
              
              _showSnackBar('已成功添加到“正在下载”列表！');
            },
            child: const Icon(Icons.download),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSection(HomeViewModel viewModel, ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(viewModel.statusMessage, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveThumbnail(BuildContext context, HomeViewModel viewModel) async {
    if (_thumbnailBytes == null) {
      _showSnackBar('封面尚未加载完成，无法保存。', isError: true);
      return;
    }
    
    _showSnackBar('正在准备保存...');
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '请选择保存位置:',
        fileName: '${viewModel.videoInfo!['id']}_thumbnail.jpg', 
        allowedExtensions: ['jpg', 'png', 'webp'],
      );
      if (outputPath != null) {
        await File(outputPath).writeAsBytes(_thumbnailBytes!);
        _showSnackBar('封面已保存到: $outputPath');
      } else {
        _showSnackBar('已取消保存。');
      }
    } catch (e) {
      _showSnackBar('保存封面失败: $e', isError: true);
    }
  }
}