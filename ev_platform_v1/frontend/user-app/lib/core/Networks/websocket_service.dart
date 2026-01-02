import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final String url;
  StreamController<dynamic>? _streamController;
  StreamSubscription? _subscription;
  VoidCallback? onConnected;     // 👈 ADD THIS
  VoidCallback? onDisconnected;

  Timer? _heartbeatTimeout;
  static const Duration _heartbeatTimeoutDuration = Duration(seconds: 45);

  WebSocketService(this.url);

  bool get isConnected => _isConnected;

  void connect() {
    _cleanupExistingConnection();

    try {
      debugPrint('Connecting to WebSocket: $url');

      _channel = WebSocketChannel.connect(Uri.parse(url));
      _streamController = StreamController<dynamic>.broadcast();

      // Listen to incoming frames
      _subscription = _channel!.stream.listen(
            (data) {
          debugPrint('WebSocket received data');

          // Reset heartbeat timer on any frame
          _resetHeartbeatTimeout();

          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.add(data);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error in service: $error');
          _isConnected = false;
          _cancelHeartbeatTimeout();

          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.addError(error);
          }
        },
        onDone: () {
          debugPrint('WebSocket connection closed in service');
          _isConnected = false;
          _cancelHeartbeatTimeout();
          _closeStreamController();
        },
      );

      // 🔥 WebSocket CONNECTED (LIVE)
      _isConnected = true;
      debugPrint('🟢 WebSocket CONNECTED (LIVE) — Handshake successful');

// ▶ notify controller
      if (onConnected != null) onConnected!();

// Start heartbeat
      _resetHeartbeatTimeout();


    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _isConnected = false;
      _cancelHeartbeatTimeout();
      _closeStreamController();
    }
  }

  void _resetHeartbeatTimeout() {
    _cancelHeartbeatTimeout();
    _heartbeatTimeout = Timer(_heartbeatTimeoutDuration, () {
      debugPrint('Heartbeat timeout - no data received for 45 seconds');
      _isConnected = false;
      if (_streamController != null && !_streamController!.isClosed) {
        _streamController!.addError('Heartbeat timeout');
      }
      _cleanupExistingConnection();
    });
  }

  void _cancelHeartbeatTimeout() {
    if (_heartbeatTimeout != null) {
      _heartbeatTimeout!.cancel();
      _heartbeatTimeout = null;
    }
  }

  void _cleanupExistingConnection() {
    _cancelHeartbeatTimeout();

    if (_subscription != null) {
      try {
        _subscription!.cancel();
      } catch (e) {
        debugPrint('Error canceling subscription: $e');
      }
      _subscription = null;
    }

    if (_channel != null) {
      try {
        if (_channel!.closeCode == null) {
          debugPrint('Closing existing WebSocket connection to: $url');
          _channel!.sink.close();
        }
      } catch (e) {
        debugPrint('Error closing existing WebSocket connection: $e');
      }
      _channel = null;
    }

    _closeStreamController();
    _isConnected = false;
  }

  void _closeStreamController() {
    if (_streamController != null && !_streamController!.isClosed) {
      try {
        _streamController!.close();
      } catch (e) {
        debugPrint('Error closing stream controller: $e');
      }
      _streamController = null;
    }
  }

  void disconnect() {
    debugPrint('Disconnecting WebSocket service');
    _handleDisconnected();
    _cleanupExistingConnection();
  }


  void _handleDisconnected() {
    if (_isConnected) {
      debugPrint('🔴 WebSocket DISCONNECTED');
    }
    _isConnected = false;
  }


  Stream get stream {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<dynamic>.broadcast();
    }
    return _streamController!.stream;
  }

  void sendMessage(String message) {
    if (_channel != null && _channel!.closeCode == null && _isConnected) {
      try {
        _channel!.sink.add(message);
        debugPrint('Message sent to WebSocket');
      } catch (e) {
        debugPrint('Error sending message to WebSocket: $e');
        _isConnected = false;
      }
    } else {
      debugPrint('Cannot send message, WebSocket not connected');
    }
  }

  bool isConnectionActive() {
    return _channel != null &&
        _subscription != null &&
        !_streamController!.isClosed &&
        _isConnected;
  }

}
