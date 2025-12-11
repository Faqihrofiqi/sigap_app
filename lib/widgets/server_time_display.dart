import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/supabase_client.dart';

class ServerTimeDisplay extends StatefulWidget {
  final bool showFullInfo;
  final TextStyle? textStyle;
  
  const ServerTimeDisplay({
    super.key,
    this.showFullInfo = false,
    this.textStyle,
  });
  
  @override
  State<ServerTimeDisplay> createState() => _ServerTimeDisplayState();
}

class _ServerTimeDisplayState extends State<ServerTimeDisplay> {
  DateTime? _serverTime;
  DateTime? _localTime;
  Timer? _timer;
  Timer? _syncTimer;
  bool _isLoading = true;
  String? _error;
  int _timeOffsetSeconds = 0; // Offset antara server dan local untuk koreksi
  
  @override
  void initState() {
    super.initState();
    _loadServerTime();
    // Update waktu secara lokal setiap detik (tanpa request ke server)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_serverTime != null && mounted) {
        final localNow = DateTime.now();
        setState(() {
          // Update waktu server dengan mempertahankan offset
          _serverTime = localNow.add(Duration(seconds: _timeOffsetSeconds));
          _localTime = localNow;
        });
      }
    });
    
    // Sync dengan server setiap 60 detik (untuk koreksi drift)
    // Interval lebih lama untuk mengurangi request ke database
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _loadServerTime();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadServerTime() async {
    try {
      final result = await SupabaseService.getServerTime();
      final localNow = DateTime.now();
      
      if (mounted) {
        setState(() {
          // Parse server time
          DateTime? parsedServerTime;
          if (result['server_time_local'] != null) {
            parsedServerTime = DateTime.parse(result['server_time_local'] as String);
          } else if (result['server_time_utc'] != null) {
            // Jika hanya ada UTC, convert ke local (UTC+7)
            final utcTime = DateTime.parse(result['server_time_utc'] as String);
            parsedServerTime = utcTime.add(const Duration(hours: 7));
          } else {
            parsedServerTime = localNow;
          }
          
          // Hitung offset antara server time dan local time saat ini
          // Ini untuk koreksi drift saat update lokal
          _timeOffsetSeconds = parsedServerTime.difference(localNow).inSeconds;
          
          _serverTime = parsedServerTime;
          _localTime = localNow;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback ke waktu lokal jika error
          _serverTime = DateTime.now();
          _localTime = DateTime.now();
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Memuat waktu server...',
            style: widget.textStyle ?? const TextStyle(fontSize: 12),
          ),
        ],
      );
    }
    
    if (_error != null && widget.showFullInfo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 4),
          Text(
            'Waktu lokal',
            style: widget.textStyle ?? TextStyle(fontSize: 12, color: Colors.orange[700]),
          ),
        ],
      );
    }
    
    if (_serverTime == null) {
      return const SizedBox.shrink();
    }
    
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd MMM yyyy');
    
    if (widget.showFullInfo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                  'Waktu Server',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(_serverTime!)} ${timeFormat.format(_serverTime!)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            if (_localTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Waktu Lokal: ${timeFormat.format(_localTime!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: widget.textStyle?.color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          timeFormat.format(_serverTime!),
          style: widget.textStyle ?? TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

