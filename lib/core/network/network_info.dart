abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    try {
      // Fallback simple: siempre intenta red; el repositorio maneja el error
      return true;
    } catch (_) {
      return false;
    }
  }
}
