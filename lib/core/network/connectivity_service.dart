import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.ethernet
      );
    });
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
