import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/check_result.dart';

class ShareButton extends StatelessWidget {
  final String domain;
  final List<SingleCheckResult> results;

  const ShareButton({
    super.key,
    required this.domain,
    required this.results,
  });

  String _generateShareText() {
    String summary = '📊 نتایج بررسی فیلترینگ برای دامنه: $domain\n\n';

    for (var result in results) {
      String statusEmoji = '';
      switch (result.status) {
        case CheckStatus.open:
          statusEmoji = '✅ باز';
          break;
        case CheckStatus.blocked:
          statusEmoji = '❌ مسدود';
          break;
        case CheckStatus.error:
          statusEmoji = '⚠️ خطا';
          break;
        default:
          statusEmoji = '❔ نامشخص';
      }
      summary += '• ${result.title}: $statusEmoji\n';
    }

    summary += '\n---\nارسال شده توسط اپلیکیشن فیلترنت';
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.share),
      label: const Text('اشتراک‌گذاری نتایج'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade600),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        final shareText = _generateShareText();
        Share.share(shareText);
      },
    );
  }
}
