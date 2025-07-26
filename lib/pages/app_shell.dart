// lib/pages/app_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart'; 
import 'history_page.dart';
import 'update_page.dart';
import 'log_page.dart';
import 'about_page.dart';
import '../services/log_service.dart';


class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    DownloadsPage(),
    HistoryPage(),
    SettingsPage(),
    UpdatePage(),
    LogPage(),
    AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogService>().addLog('应用 UI 加载完成。');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.download_outlined),
                selectedIcon: Icon(Icons.download),
                label: Text('正在下载'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('历史记录'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('设置'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.update),
                label: Text('软件更新'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                label: Text('日志'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                label: Text('关于'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}