import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/check_result.dart';
import 'log_service.dart'; // Import LogService

class CheckService {
  static const List<String> _blockedIps = [
    '10.10.34.34',
    '10.10.34.35',
    '10.10.34.36',
  ];

  static const String _sniProbeHost = 'google.com';
  static const int _timeoutSeconds = 15; // Common timeout

  // Helper to determine if an IP is blocked based on the provided PHP logic
  bool _isIpBlocked(String ip) {
    return _blockedIps.contains(ip);
  }

  Future<SingleCheckResult> checkDns(String domain) async {
    final result = SingleCheckResult(title: 'DNS');
    LogService().info('Starting DNS check for $domain');

    try {
      // PHP equivalent resolves both lower and upper case.
      // In Dart's InternetAddress.lookup, domain resolution is generally case-insensitive
      // or handled by DNS resolvers. However, to strictly follow the PHP logic of
      // resolving both cases, we can simulate it if it makes a difference to the resolver.
      // But typically, InternetAddress.lookup is sufficient for a standard DNS lookup.
      // If the PHP code implies checking two different DNS resolvers/behavior for case,
      // Dart's standard lookup might behave differently.
      // For now, we'll focus on the core IP blocking check.

      final response = await InternetAddress.lookup(domain)
          .timeout(Duration(seconds: _timeoutSeconds));
      
      if (response.isEmpty) {
        result.status = CheckStatus.error;
        result.details = 'پاسخی از DNS دریافت نشد';
        LogService().warning('DNS check for $domain: No IP response');
        return result;
      }

      final ip = response.first.address;
      if (_isIpBlocked(ip)) {
        result.status = CheckStatus.blocked;
        result.details = 'IP مسدودسازی شناسایی شد: $ip';
        LogService().info('DNS check for $domain: BLOCKED (IP: $ip)');
      } else {
        result.status = CheckStatus.open;
        result.details = 'IP: $ip';
        LogService().info('DNS check for $domain: OPEN (IP: $ip)');
      }
    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'بررسی DNS زمان‌بر شد (Timeout)';
      LogService().error('DNS check for $domain: Timeout', TimeoutException('DNS check timed out'));
    } on SocketException catch (e) {
      result.status = CheckStatus.error;
      // More specific error details based on PHP logic (e.g., address not found)
      result.details = 'خطای DNS: آدرس یافت نشد یا مشکل شبکه';
      LogService().error('DNS check for $domain: SocketException: ${e.message}', e);
    } catch (e, st) {
      result.status = CheckStatus.error;
      result.details = 'یک خطای نامشخص در DNS رخ داد';
      LogService().fatal('DNS check for $domain: Unknown error', e, st);
    }
    return result;
  }

  Future<SingleCheckResult> checkHttp(String domain) async {
    final result = SingleCheckResult(title: 'HTTP');
    LogService().info('Starting HTTP check for $domain');
    final url = Uri.parse('http://$domain');
    
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'
      }).timeout(Duration(seconds: _timeoutSeconds));

      // PHP logic: check for specific blocking patterns in title or iframe
      final responseBody = response.body;
      final titlePattern = RegExp(r'<title>10\.10\.34\.3[4-6]<\/title>', caseSensitive: false);
      final iframePattern = RegExp(r'<iframe.*?src="http:\/\/10\.10\.34\.3[4-6]', caseSensitive: false);

      if (titlePattern.hasMatch(responseBody) || iframePattern.hasMatch(responseBody)) {
        result.status = CheckStatus.blocked;
        result.details = 'صفحه فیلترینگ شناسایی شد';
        LogService().info('HTTP check for $domain: BLOCKED (Filter page detected)');
      } else {
        result.status = CheckStatus.open;
        result.details = 'وضعیت HTTP: ${response.statusCode}';
        LogService().info('HTTP check for $domain: OPEN (Status: ${response.statusCode})');
      }
    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'بررسی HTTP زمان‌بر شد (Timeout)';
      LogService().error('HTTP check for $domain: Timeout', TimeoutException('HTTP check timed out'));
    } on SocketException catch (e) {
      result.status = CheckStatus.error;
      result.details = 'خطای اتصال در لایه سوکت HTTP';
      LogService().error('HTTP check for $domain: SocketException: ${e.message}', e);
    } catch (e, st) {
      result.status = CheckStatus.error;
      result.details = 'خطای نامشخص HTTP';
      LogService().fatal('HTTP check for $domain: Unknown error', e, st);
    }
    return result;
  }

  Future<SingleCheckResult> checkSni(String domain) async {
    final result = SingleCheckResult(title: 'SNI');
    LogService().info('Starting SNI check for $domain');

    try {
      // PHP logic uses stream_socket_client and then checks for SSL/TLS errors.
      // In Dart, SecureSocket.secure directly performs the TLS handshake.
      // We need to interpret TlsException and specific SocketExceptions as blocking.

      final socket = await Socket.connect(
        _sniProbeHost,
        443,
        timeout: Duration(seconds: _timeoutSeconds),
      );
      LogService().debug('SNI check for $domain: TCP connection established to $_sniProbeHost:443');

      // Attempt TLS handshake using the target domain as SNI host
      final secureSocket = await SecureSocket.secure(
        socket,
        host: domain, // This is the SNI part
        onBadCertificate: (certificate) {
          // In PHP, verify_peer_name is false. We can do similar here if needed
          // to bypass certificate validation, focusing only on handshake success.
          // However, verify_peer is true in PHP, implying some validation.
          // For simplicity and common use-case, let's allow self-signed or invalid certs if any.
          // But a failed certificate usually implies an issue.
          // For now, let's return true to allow handshake continuation regardless of cert issues
          // unless it's explicitly a connection/handshake failure.
          LogService().warning('SNI check for $domain: Bad certificate encountered for ${certificate.subject}. Allowing for check purposes.');
          return true; // Allows connection even with bad certificates
        },
        // The PHP code does not explicitly disable compression.
        // It uses verify_peer=true, verify_peer_name=false.
        // The default Dart behavior is usually secure enough.
      ).timeout(Duration(seconds: _timeoutSeconds));

      result.status = CheckStatus.open;
      result.details = 'اتصال TLS/SNI برقرار شد';
      LogService().info('SNI check for $domain: OPEN (TLS connection established)');
      
      secureSocket.destroy();

    } on TimeoutException {
      result.status = CheckStatus.error;
      result.details = 'بررسی SNI زمان‌بر شد (Timeout)';
      LogService().error('SNI check for $domain: Timeout', TimeoutException('SNI check timed out'));
    } on TlsException catch (e) {
      // This is the direct equivalent of SSL/TLS related errors in PHP.
      // Often indicates active blocking.
      result.status = CheckStatus.blocked;
      result.details = 'اتصال TLS/SNI قطع شد (Handshake Failed)';
      LogService().info('SNI check for $domain: BLOCKED (TLS Handshake Failed: ${e.message})');
    } on SocketException catch (e) {
      // PHP's stream_socket_client error handling for 'Connection reset by peer'
      // or 'Connection refused' are often signs of blocking.
      if (e.osError?.message.contains('Connection reset by peer') ?? false) {
          result.status = CheckStatus.blocked;
          result.details = 'اتصال SNI توسط میزبان قطع شد';
          LogService().info('SNI check for $domain: BLOCKED (Connection reset by peer)');
      } else if (e.osError?.message.contains('Connection refused') ?? false) {
          result.status = CheckStatus.blocked; // Often a sign of blocking or no service
          result.details = 'اتصال SNI رد شد (Connection refused)';
          LogService().info('SNI check for $domain: BLOCKED (Connection refused)');
      } else {
          result.status = CheckStatus.error;
          result.details = 'خطای اتصال در لایه سوکت SNI: ${e.message}';
          LogService().error('SNI check for $domain: SocketException: ${e.message}', e);
      }
    } catch (e, st) {
      result.status = CheckStatus.error;
      result.details = 'خطای نامشخص در SNI';
      LogService().fatal('SNI check for $domain: Unknown error', e, st);
    }
    return result;
  }
}