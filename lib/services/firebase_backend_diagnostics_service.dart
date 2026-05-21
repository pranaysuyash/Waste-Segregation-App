import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../utils/waste_app_logger.dart';

/// Monitors Firebase-related backend host resolution and logs outages once.
///
/// Purpose:
/// - Distinguish generic TLS noise from backend DNS/host-level outages.
/// - Print one "outage started" event and one "recovered" event per outage.
class FirebaseBackendDiagnosticsService with WidgetsBindingObserver {
  factory FirebaseBackendDiagnosticsService() => _instance;
  FirebaseBackendDiagnosticsService._internal();
  static final FirebaseBackendDiagnosticsService _instance =
      FirebaseBackendDiagnosticsService._internal();

  static const Map<String, String> _serviceHosts = {
    'firestore': 'firestore.googleapis.com',
    'firebase_auth_identity_toolkit': 'identitytoolkit.googleapis.com',
    'firebase_auth_secure_token': 'securetoken.googleapis.com',
    'firebase_functions_asia_south1':
        'asia-south1-waste-segregation-app-df523.cloudfunctions.net',
    'firebase_logging_transport': 'firebaselogging-pa.googleapis.com',
  };

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  Duration _periodicCheckInterval = const Duration(minutes: 2);

  final Map<String, bool> _hostHealthy = {};
  bool _initialized = false;
  bool _outageActive = false;

  Future<void> initialize({
    Duration periodicCheckInterval = const Duration(minutes: 2),
  }) async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    _periodicCheckInterval = periodicCheckInterval;
    WidgetsBinding.instance.addObserver(this);

    // Initialize baseline state before periodic checks.
    await _runCheck(trigger: 'startup');
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (!online) {
        WasteAppLogger.warning(
          'backend_connectivity_offline',
          context: {
            'connectivity_results': results.map((r) => r.name).toList()
          },
        );
        return;
      }

      unawaited(_runCheck(trigger: 'connectivity_restored'));
    });
    _startPeriodicChecks();

    WasteAppLogger.info(
      'firebase_backend_diagnostics_initialized',
      context: {
        'check_interval_seconds': periodicCheckInterval.inSeconds,
        'host_count': _serviceHosts.length,
      },
    );
  }

  Future<void> _runCheck({required String trigger}) async {
    final failedServices = <Map<String, String>>[];

    for (final entry in _serviceHosts.entries) {
      final service = entry.key;
      final host = entry.value;

      final result = await _checkHost(host);
      final wasHealthy = _hostHealthy[service] ?? true;
      _hostHealthy[service] = result.ok;

      if (!result.ok) {
        failedServices.add({
          'service': service,
          'host': host,
          'reason': result.reason ?? 'unknown',
        });
      }

      if (wasHealthy && !result.ok) {
        WasteAppLogger.warning(
          'backend_host_outage_started',
          context: {
            'service': service,
            'host': host,
            'trigger': trigger,
            'reason': result.reason,
          },
        );
      } else if (!wasHealthy && result.ok) {
        WasteAppLogger.info(
          'backend_host_recovered',
          context: {
            'service': service,
            'host': host,
            'trigger': trigger,
          },
        );
      }
    }

    if (failedServices.isNotEmpty && !_outageActive) {
      _outageActive = true;
      WasteAppLogger.severe(
        'backend_outage_window_started',
        context: {
          'trigger': trigger,
          'failed_services': failedServices,
        },
      );
      return;
    }

    if (failedServices.isEmpty && _outageActive) {
      _outageActive = false;
      WasteAppLogger.info(
        'backend_outage_window_recovered',
        context: {'trigger': trigger},
      );
    }
  }

  void _startPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_periodicCheckInterval, (_) {
      unawaited(_runCheck(trigger: 'periodic'));
    });
  }

  void _stopPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_runCheck(trigger: 'resumed'));
        _startPeriodicChecks();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopPeriodicChecks();
        break;
    }
  }

  Future<_HostCheckResult> _checkHost(String host) async {
    try {
      final lookup = await InternetAddress.lookup(host).timeout(
        const Duration(seconds: 4),
      );
      if (lookup.isEmpty) {
        return const _HostCheckResult(
          ok: false,
          reason: 'dns_lookup_empty',
        );
      }

      return const _HostCheckResult(ok: true);
    } on SocketException catch (e) {
      return _HostCheckResult(
          ok: false,
          reason: 'socket_exception:${e.osError?.message ?? e.message}');
    } on TimeoutException {
      return const _HostCheckResult(ok: false, reason: 'dns_timeout');
    } catch (e) {
      return _HostCheckResult(ok: false, reason: 'unknown_error:$e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _stopPeriodicChecks();
  }
}

class _HostCheckResult {
  const _HostCheckResult({
    required this.ok,
    this.reason,
  });

  final bool ok;
  final String? reason;
}
