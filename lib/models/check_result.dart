import 'package:hive/hive.dart';

part 'check_result.g.dart'; // Hive generator will create this file

// An enum to represent the status of each check
@HiveType(typeId: 1)
enum CheckStatus {
  @HiveField(0)
  checking,

  @HiveField(1)
  open,

  @HiveField(2)
  blocked,

  @HiveField(3)
  error,

  @HiveField(4)
  unknown,
}

// Represents the result of a single check (like DNS or HTTP)
class SingleCheckResult {
  final String title;
  CheckStatus status;
  String details;

  SingleCheckResult({
    required this.title,
    this.status = CheckStatus.unknown,
    this.details = 'هنوز بررسی نشده',
  });
}

// Represents the complete check result for a domain, used for history
@HiveType(typeId: 0)
class DomainCheckResult extends HiveObject {
  @HiveField(0)
  late String domain;

  @HiveField(1)
  late DateTime timestamp;

  @HiveField(2)
  late CheckStatus dnsStatus;

  @HiveField(3)
  late String dnsDetails;

  @HiveField(4)
  late CheckStatus httpStatus;

  @HiveField(5)
  late String httpDetails;

  @HiveField(6)
  late CheckStatus sniStatus;

  @HiveField(7)
  late String sniDetails;
  
  // A simple getter to determine the overall status
  CheckStatus get overallStatus {
    if (dnsStatus == CheckStatus.blocked || 
        httpStatus == CheckStatus.blocked || 
        sniStatus == CheckStatus.blocked) {
      return CheckStatus.blocked;
    }
    if (dnsStatus == CheckStatus.open &&
        httpStatus == CheckStatus.open &&
        sniStatus == CheckStatus.open) {
      return CheckStatus.open;
    }
    return CheckStatus.unknown; // Or can be considered error if any has error
  }
}
