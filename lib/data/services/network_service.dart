import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  online,
  offline,
}

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _lastKnownStatus = NetworkStatus.online;
  Timer? _periodicCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  NetworkService() {
    _init();
  }

  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;
  NetworkStatus get currentStatus => _lastKnownStatus;

  Future<NetworkStatus> checkStatus() async {
    final status = await _verifyActualInternet();
    _notifyIfChanged(status);
    return status;
  }

  void _init() {
    // 1. Initial check
    checkStatus();

    // 2. Stream listener on network interface changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) async {
      final status = await _verifyActualInternet(results);
      _notifyIfChanged(status);
    });

    // 3. Periodic heartbeat check (every 3 seconds) for instant detection
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final status = await _verifyActualInternet();
      _notifyIfChanged(status);
    });
  }

  Future<NetworkStatus> _verifyActualInternet([List<ConnectivityResult>? results]) async {
    try {
      final connectivityResults = results ?? await _connectivity.checkConnectivity();
      if (connectivityResults.isEmpty ||
          connectivityResults.every((r) => r == ConnectivityResult.none)) {
        return NetworkStatus.offline;
      }

      // Perform DNS lookup check to verify real internet reachability
      final lookupResult = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 2));

      if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
        return NetworkStatus.online;
      }
      return NetworkStatus.offline;
    } catch (_) {
      return NetworkStatus.offline;
    }
  }

  void _notifyIfChanged(NetworkStatus status) {
    if (status != _lastKnownStatus) {
      _lastKnownStatus = status;
      _statusController.add(status);
    }
  }

  void dispose() {
    _periodicCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(() => service.dispose());
  return service;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkServiceProvider);
  return service.onStatusChanged;
});
