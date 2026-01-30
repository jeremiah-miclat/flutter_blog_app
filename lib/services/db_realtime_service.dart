import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService {
  SupabaseRealtimeService._();

  static final SupabaseRealtimeService instance = SupabaseRealtimeService._();

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  RealtimeChannel? _channel;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final supabaseClient = Supabase.instance.client;
    _channel = supabaseClient.channel('public:realtime');
    debugPrint("Realtime Channel Started");
    debugPrint("Channel: $_channel");
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'blogs',
          callback: (payload) {
            debugPrint(
              'Type: ${payload.eventType} '
              'New: ${payload.newRecord} '
              'Old: ${payload.oldRecord}',
            );
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            debugPrint(
              'Type: ${payload.eventType} '
              'New: ${payload.newRecord} '
              'Old: ${payload.oldRecord}',
            );
          },
        )
        .subscribe();
  }

  Future<void> stop() async {
    final supabaseClient = Supabase.instance.client;
    final channel = _channel;
    _channel = null;
    _started = false;

    if (channel != null) {
      await supabaseClient.removeChannel(channel);
      debugPrint("Realtime Channel Listener Removed");
    }
  }

  void dispose() {
    _controller.close();
    debugPrint("Realtime Channel closed");
  }
}
