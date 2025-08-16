import 'package:flutter/material.dart';
import '../models/check_result.dart';

class ResultCard extends StatelessWidget {
  final SingleCheckResult result;

  const ResultCard({super.key, required this.result});

  // Helper method to get the right icon based on status
  Widget _getIconForStatus(CheckStatus status) {
    switch (status) {
      case CheckStatus.checking:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case CheckStatus.open:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case CheckStatus.blocked:
        return const Icon(Icons.cancel, color: Colors.red, size: 28);
      case CheckStatus.error:
        return const Icon(Icons.error, color: Colors.orange, size: 28);
      case CheckStatus.unknown:
      default:
        return const Icon(Icons.help, color: Colors.grey, size: 28);
    }
  }

  // Helper method to get the right text based on status
  String _getTextForStatus(CheckStatus status) {
    switch (status) {
      case CheckStatus.checking:
        return "در حال بررسی";
      case CheckStatus.open:
        return "باز";
      case CheckStatus.blocked:
        return "مسدود";
      case CheckStatus.error:
        return "خطا";
      case CheckStatus.unknown:
      default:
        return "نامشخص";
    }
  }
  
  // Helper method to get the right color based on status
  Color _getColorForStatus(CheckStatus status) {
    switch (status) {
      case CheckStatus.open:
        return Colors.green;
      case CheckStatus.blocked:
        return Colors.red;
      case CheckStatus.error:
        return Colors.orange;
      case CheckStatus.checking:
      case CheckStatus.unknown:
      default:
        return Colors.grey.shade400;
    }
  }


  @override
  Widget build(BuildContext context) {
    final statusColor = _getColorForStatus(result.status);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Row(
        children: [
          _getIconForStatus(result.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTextForStatus(result.status),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
