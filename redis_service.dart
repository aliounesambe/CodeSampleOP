import 'dart:async';
import 'package:flutter/material.dart';
import 'package:redis/redis.dart';

/// Maintains a live health-checked connection to a Redis backend and
/// exposes connectivity state to the widget tree via ChangeNotifier
/// (the same "observable view model" pattern used by SwiftUI's
/// ObservableObject / @Published).
class RedisService extends ChangeNotifier {
  final String host = 'cmsc436-0101-redis.cs.umd.edu';
  final int port = 6380;
  Timer? _probeTimer;
  bool _isConnected = false;
  String? _username;
  String? _password;
  BuildContext? _context;

  static const connectionTimeout = Duration(seconds: 1);
  static const probeInterval = Duration(seconds: 10);

  bool get isConnected => _isConnected;

  void initialize(BuildContext context, String username, String password) {
    _context = context;
    _username = username;
    _password = password;
    _startProbing();
  }

  void _startProbing() {
    _probeTimer?.cancel();

    _probeTimer = Timer.periodic(probeInterval, (_) {
      _probeConnection();
    });

    // do an initial probe immediately rather than waiting for the first tick
    _probeConnection();
  }

  Future<void> _probeConnection() async {
    if (_username == null || _password == null) return;

    RedisConnection? probeConnection;
    try {
      probeConnection = RedisConnection();
      final command =
          await probeConnection.connect(host, port).timeout(connectionTimeout);

      await command.send_object(['AUTH', _username!, _password!]).timeout(
          connectionTimeout);

      if (!_isConnected) {
        _isConnected = true;
        _showConnectionStatus(true);
        notifyListeners();
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _showConnectionStatus(false);
        notifyListeners();
      }
    } finally {
      try {
        await probeConnection?.close();
      } catch (e) {
        // ignore cleanup errors
      }
    }
  }

  void _showConnectionStatus(bool connected) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).clearSnackBars();

      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(connected
              ? 'Redis connection restored'
              : 'Redis connection lost'),
          duration: const Duration(seconds: 3),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<dynamic> execute(String command, List<String> args) async {
    if (!_isConnected) {
      throw Exception(
          'Redis is currently disconnected. Please wait for connection to be restored.');
    }

    RedisConnection? connection;
    try {
      connection = RedisConnection();
      final cmd =
          await connection.connect(host, port).timeout(connectionTimeout);

      await cmd.send_object(['AUTH', _username!, _password!]).timeout(
          connectionTimeout);

      final result =
          await cmd.send_object([command, ...args]).timeout(connectionTimeout);

      return result;
    } finally {
      try {
        await connection?.close();
      } catch (e) {
        // ignore cleanup errors
      }
    }
  }

  @override
  void dispose() {
    _probeTimer?.cancel();
    super.dispose();
  }
}
