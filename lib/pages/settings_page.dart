// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController(
      text: context.read<SettingsService>().proxyUrl,
    );
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    if (_proxyController.text != settings.proxyUrl) {
      _proxyController.text = settings.proxyUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('外观', theme),
          _buildThemeModeSelector(context, settings),
          _buildSeedColorSelector(context, settings),
          _buildFontSizeSelector(context, settings),
          const Divider(height: 32),
          _buildSectionTitle('下载', theme),
          _buildDownloadPathSelector(context, settings),
          _buildAskBeforeDownloadingSwitch(context, settings),
          _buildAutoMergeSwitch(context, settings),
          const Divider(height: 32),
          _buildSectionTitle('网络代理', theme),
          Card(
            child: Column(
              children: [
                // ---  SwitchListTile 的文本和逻辑 ---
                SwitchListTile(
                  title: const Text('启用自定义代理'),
                  subtitle: const Text('关闭后将使用系统直接网络连接'),
                  value: settings.enableCustomProxy,
                  onChanged: (value) => settings.updateProxySettings(enableCustomProxy: value),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _proxyController,
                    // 只有当开关打开时，输入框才可用
                    enabled: settings.enableCustomProxy,
                    decoration: const InputDecoration(
                      labelText: '代理服务器地址',
                      hintText: '例如: http://127.0.0.1:7890',
                      border: OutlineInputBorder(),
                    ),
                    // 当文本变化时，实时更新设置
                    onChanged: (value) => settings.updateProxySettings(proxyUrl: value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: theme.textTheme.titleLarge),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, SettingsService settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('主题模式', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) settings.updateThemeMode(value);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) settings.updateThemeMode(value);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) settings.updateThemeMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSeedColorSelector(BuildContext context, SettingsService settings) {
    final colors = [
      Colors.orange, 
      Colors.deepPurple, 
      Colors.blue, 
      Colors.teal, 
      Colors.green, 
      Colors.red, 
      Colors.pink
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('主题颜色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                return InkWell(
                  onTap: () => settings.updateSeedColor(color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: settings.seedColor.value == color.value
                        ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                        : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector(BuildContext context, SettingsService settings) {
    String getFontSizeLabel(double multiplier) {
      if (multiplier < 0.9) return '偏小';
      if (multiplier < 1.1) return '正常';
      if (multiplier < 1.3) return '偏大';
      return '最大';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('字体大小', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.format_size, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: settings.fontSizeMultiplier,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: getFontSizeLabel(settings.fontSizeMultiplier),
                    onChanged: (value) {
                      settings.updateFontSize(value);
                    },
                  ),
                ),
                const Icon(Icons.format_size, size: 32, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadPathSelector(BuildContext context, SettingsService settings) {
    return Card(
      child: ListTile(
        title: const Text('默认下载路径'),
        subtitle: Text(settings.defaultDownloadPath ?? '未设置 (将使用系统默认下载文件夹)'),
        trailing: const Icon(Icons.folder),
        onTap: () async {
          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
          if (selectedDirectory != null) {
            settings.updateDownloadPath(selectedDirectory);
          }
        },
      ),
    );
  }
  
  Widget _buildAskBeforeDownloadingSwitch(BuildContext context, SettingsService settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('每次下载前询问保存位置'),
        value: settings.askBeforeDownloading,
        onChanged: (value) => settings.updateAskBeforeDownloading(value),
      ),
    );
  }

  Widget _buildAutoMergeSwitch(BuildContext context, SettingsService settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('自动合并最佳音轨'),
        subtitle: const Text('当下载无声视频时，自动寻找并合并最高质量的音轨。'),
        value: settings.autoMergeAudio,
        onChanged: (value) => settings.updateAutoMergeAudio(value),
      ),
    );
  }
}