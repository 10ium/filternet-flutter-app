import 'dart:async';
import 'dart:io';
// The import path is now corrected to match the package name in pubspec.yaml
import 'package:dns_client_over_https/dns_client_over_https.dart';
import 'package:http/http.dart' as http;
import '../models/check_result.dart';

class CheckService {
  // Common Iranian filtering IP addresses
  static const List<String> _blockedIps = [
    '10.10.34.34',
    '10.10.34.35',
    '10.10.34.36',
  ];

  // A known open host to establish a TLS connection for SNI check
  static const String _sniProbeHost = 'google.com';
  static const int _timeoutSeconds = 15;

  /// Checks the DNS resolution of a domain.
  /// Returns a SingleCheckResult with the status.
  Future<SingleCheckResult> checkDns(String domain) async {
    final result = SingleCheckResult(title: 'DNS');
    try {
      final client = DnsOverHttps(DnsOverHttps.google);
      final response = await client.lookup(domain, type: DnsRecordType.A)
          .timeout(Duration(seconds: _timeoutSeconds));
      
      if (response.isEmpty) {
        result.status = CheckStatus.error;
        result.details = 'پاسخی دریافت نشد';
        return result;
      }

      final ip = response.first.address;
      if (_blockedIps.contains(ip)) {
        result.status = CheckStatus.blocked;
        result.details = 'IP مسدودسازی: $ip';
      } else {
        result.status = CheckStatus.open;
        result.details = 'IP: $ip';
      }
    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'بررسی DNS زمان‌بر شد (Timeout)';
    } catch (e) {
      result.status = CheckStatus.error;
      result.details = 'خطای DNS: آدرس یافت نشد';
    }
    return result;
  }

  /// Checks the HTTP response of a URL.
  /// Returns a SingleCheckResult with the status.
  Future<SingleCheckResult> checkHttp(String domain) async {
    final result = SingleCheckResult(title: 'HTTP');
    final url = Uri.parse('http://$domain');
    
    try {
      // We only need headers and a small part of the body.
      final response = await http.get(url)
          .timeout(Duration(seconds: _timeoutSeconds));

      final responseBody = response.body;
      final titlePattern = RegExp(r'<title>10\.10\.34\.3[4-6]<\/title>', caseSensitive: false);
      final iframePattern = RegExp(r'<iframe.*?src="http:\/\/10\.10\.34\.3[4-6]', caseSensitive: false);

      if (titlePattern.hasMatch(responseBody) || iframePattern.hasMatch(responseBody)) {
        result.status = CheckStatus.blocked;
        result.details = 'صفحه فیلترینگ شناسایی شد';
      } else {
        result.status = CheckStatus.open;
        result.details = 'وضعیت: ${response.statusCode}';
      }
    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'بررسی HTTP زمان‌بر شد (Timeout)';
    } on SocketException {
      result.status = CheckStatus.error;
      result.details = 'خطای اتصال در لایه سوکت';
    } catch (e) {
      result.status = CheckStatus.error;
      result.details = 'خطای نامشخص HTTP';
    }
    return result;
  }

  /// Checks for TLS SNI based filtering.
  /// Returns a SingleCheckResult with the status.
  Future<SingleCheckResult> checkSni(String domain) async {
    final result = SingleCheckResult(title: 'SNI');
    try {
      final socket = await SecureSocket.connect(
        _sniProbeHost,
        443,
        hostName: domain, 
        timeout: Duration(seconds: _timeoutSeconds),
      );
      result.status = CheckStatus.open;
      result.details = 'اتصال TLS برقرار شد';
      await socket.destroy();
    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'اتصال TLS زمان‌بر شد (Timeout)';
    } on TlsException {
      result.status = CheckStatus.blocked;
      result.details = 'اتصال TLS قطع شد (Handshake)';
    } on SocketException catch (e) {
      if (e.osError?.message.contains('Connection reset by peer') ?? false) {
          result.status = CheckStatus.blocked;
          result.details = 'اتصال توسط میزبان قطع شد';
      } else {
          result.status = CheckStatus.error;
          result.details = 'خطای اتصال در لایه سوکت';
      }
    } catch (e) {
      result.status = CheckStatus.error;
      result.details = 'خطای نامشخص TLS';
    }
    return result;
  }
}
