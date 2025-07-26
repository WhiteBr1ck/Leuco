import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:url_launcher/url_launcher.dart';

// ---  Widget 转换为 StatefulWidget ---
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // ---  创建一个状态变量来存储版本信息 ---
  String _version = '正在加载...'; 

  final String appName = 'Leuco';
  final String appDescription = '一个基于 yt-dlp 的、简洁易用的视频下载工具。';
  final String githubUrl = 'https://github.com/WhiteBr1ck/Leuco';

  @override
  void initState() {
    super.initState();
    // ---  在页面初始化时，调用方法去加载版本信息 ---
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // ---  获取到信息后，更新状态，UI会自动刷新 ---
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                  ),
                  const SizedBox(height: 16),
                  Text(appName, style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    appDescription,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('版本号'),
                      // --- 从状态中读取的版本号 ---
                      subtitle: Text(_version),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('源代码'),
                      subtitle: const Text('在 GitHub 上查看'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _launchURL(githubUrl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}