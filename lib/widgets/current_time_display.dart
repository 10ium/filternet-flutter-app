import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart' as intl;

class CurrentTimeDisplay extends StatefulWidget {
  const CurrentTimeDisplay({super.key});

  @override
  State<CurrentTimeDisplay> createState() => _CurrentTimeDisplayState();
}

class _CurrentTimeDisplayState extends State<CurrentTimeDisplay> {
  late Timer _timer;
  late tz.TZDateTime _now;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // زمان را هر دقیقه به‌روز می‌کنیم تا بهینه‌تر باشد
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      // زمان فعلی را در منطقه زمانی محلی (که در main.dart روی تهران تنظیم کردیم) می‌گیریم
      _now = tz.TZDateTime.now(tz.local);
    });
  }

  @override
  Widget build(BuildContext context) {
    // تبدیل میلادی به شمسی
    final jalaliDate = Jalali.fromDateTime(_now);
    final jalaliFormatter = jalaliDate.formatter;

    // فرمت‌بندی تاریخ میلادی
    final gregorianFormatter = intl.DateFormat('yyyy/MM/dd – HH:mm', 'en_US');
    final gregorianWordFormatter = intl.DateFormat('EEEE, d MMMM yyyy', 'en_US');

    // CORRECTED: Extracting hour and minute from _now (TZDateTime)
    final String currentHour = _now.hour.toString().padLeft(2, '0');
    final String currentMinute = _now.minute.toString().padLeft(2, '0');


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeRow(
            'شمسی (حروف):',
            '${jalaliFormatter.wN}, ${jalaliFormatter.d} ${jalaliFormatter.mN} ${jalaliFormatter.yyyy}',
          ),
          _buildTimeRow(
            'شمسی (اعداد):',
            // CORRECTED: Using _now for hour and minute
            '${jalaliFormatter.yyyy}/${jalaliFormatter.mm}/${jalaliFormatter.dd} – $currentHour:$currentMinute',
          ),
          const Divider(color: Colors.grey, height: 20),
          _buildTimeRow(
            'میلادی (حروف):',
            gregorianWordFormatter.format(_now),
          ),
          _buildTimeRow(
            'میلادی (اعداد):',
            gregorianFormatter.format(_now),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            // اعداد و تاریخ انگلیسی را چپ‌چین نگه می‌داریم
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}