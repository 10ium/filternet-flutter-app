import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String _logs = 'در حال بارگذاری لاگ‌ها...';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await LogService().getLogs();
      setState(() {
        _logs = logs.isEmpty ? 'هیچ لاگی برای نمایش وجود ندارد.' : logs;
      });
    } catch (e) {
      setState(() {
        _logs = 'خطا در بارگذاری لاگ‌ها: $e';
      });
      LogService().error('Error loading logs for display', e); // Log the error
    }
  }

  Future<void> _shareLogs() async {
    try {
      final logs = await LogService().getLogs();
      if (logs.isNotEmpty) {
        await Share.share(logs, subject: 'Log Report from FilterNet App');
        LogService().info('Logs shared successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هیچ لاگی برای اشتراک‌گذاری وجود ندارد.')),
        );
      }
    } catch (e) {
      LogService().error('Error sharing logs', e); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اشتراک‌گذاری لاگ‌ها: $e')),
      );
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پاک کردن لاگ‌ها'),
        content: const Text('آیا مطمئن هستید که می‌خواهید تمام لاگ‌ها را پاک کنید؟'),
        actions: [
          TextButton(
            child: const Text('لغو'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('پاک کردن'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LogService().clearLogs();
        setState(() {
          _logs = 'هیچ لاگی برای نمایش وجود ندارد.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لاگ‌ها با موفقیت پاک شدند.')),
        );
        LogService().info('Logs cleared successfully');
      } catch (e) {
        LogService().error('Error clearing logs', e); // Log the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در پاک کردن لاگ‌ها: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لاگ‌های برنامه'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'اشتراک‌گذاری لاگ‌ها',
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'پاک کردن لاگ‌ها',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          // Forcing LTR for log content for readability as they are mostly English/timestamps
          child: Text(
            _logs,
            style: const TextStyle(
              fontFamily: 'monospace', // Use a monospace font for logs
              fontSize: 12,
              color: Colors.white70,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}