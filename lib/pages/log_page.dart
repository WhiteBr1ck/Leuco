// lib/pages/log_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logService = context.watch<LogService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清除日志',
            onPressed: logService.logs.isEmpty ? null : () {
              context.read<LogService>().clearLogs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: SwitchListTile(
              title: const Text('开启调试模式'),
              subtitle: const Text('开启后将在此处记录详细的操作日志'),
              value: logService.isDebugging,
              onChanged: (value) {
                context.read<LogService>().toggleDebugging(value);
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: logService.logs.isEmpty
                ? const Center(child: Text('暂无日志记录'))
                : ListView.builder(
                    reverse: false, 
                    itemCount: logService.logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          logService.logs[index],
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}