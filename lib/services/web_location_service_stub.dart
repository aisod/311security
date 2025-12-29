/// Stub for web location service on non-web platforms
class WebLocationService {
  Future<Map<String, double>> getCurrentPosition({Duration timeout = const Duration(seconds: 30)}) async {
    throw UnsupportedError('WebLocationService is only available on web');
  }

  bool isSupported() {
    return false;
  }
}


