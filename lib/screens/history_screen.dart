import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/check_result.dart';
import '../providers/app_provider.dart';
import 'package:intl/intl.dart' as intl;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showDetailsDialog(BuildContext context, DomainCheckResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use Directionality for the title to align it correctly
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'جزئیات برای: ${result.domain}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              // Make sure timestamp is aligned properly
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  intl.DateFormat('yyyy/MM/dd – HH:mm').format(result.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                  textDirection: TextDirection.ltr,
                ),
              ),
              const Divider(height: 32),
              // Details rows are fine as they are handled internally
              _buildDetailRow('DNS', result.dnsStatus, result.dnsDetails),
              _buildDetailRow('HTTP', result.httpStatus, result.httpDetails),
              _buildDetailRow('SNI', result.sniStatus, result.sniDetails),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بستن'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, CheckStatus status, String details) {
    String statusText;
    Color statusColor;

    switch (status) {
      case CheckStatus.open:
        statusText = 'باز';
        statusColor = Colors.green;
        break;
      case CheckStatus.blocked:
        statusText = 'مسدود';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'خطا/نامشخص';
        statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              children: [
                TextSpan(
                  text: statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(details, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final history = appProvider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه بررسی‌ها'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'پاک کردن تاریخچه',
              onPressed: () {
                // Show a confirmation dialog before clearing
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تایید'),
                    content: const Text('آیا از پاک کردن کل تاریخچه مطمئن هستید؟'),
                    actions: [
                      TextButton(
                        child: const Text('لغو'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: const Text('پاک کردن'),
                        onPressed: () {
                          context.read<AppProvider>().clearHistory();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'تاریخچه‌ای وجود ندارد.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final overallStatus = item.overallStatus;

                // Wrap ListTile with Dismissible for swipe-to-delete functionality
                return Dismissible(
                  key: ValueKey(item.timestamp.toIso8601String()), // Unique key for Dismissible
                  direction: DismissDirection.endToStart, // Only allow swipe from right to left
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف آیتم'),
                        content: Text('آیا مطمئن هستید که می‌خواهید "${item.domain}" را از تاریخچه حذف کنید؟'),
                        actions: [
                          TextButton(
                            child: const Text('خیر'),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            child: const Text('بله'),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<AppProvider>().deleteHistoryItem(item);
                    // Optionally show a SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"${item.domain}" از تاریخچه حذف شد.')),
                    );
                  },
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: ListTile(
                      leading: Icon(
                        overallStatus == CheckStatus.blocked ? Icons.cancel : Icons.check_circle,
                        color: overallStatus == CheckStatus.blocked ? Colors.red : Colors.green,
                      ),
                      title: Text(item.domain),
                      subtitle: Text(
                        intl.DateFormat('yyyy/MM/dd – HH:mm').format(item.timestamp),
                      ),
                      onTap: () => _showDetailsDialog(context, item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}