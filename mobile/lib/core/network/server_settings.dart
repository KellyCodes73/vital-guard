import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

/// Dirección del backend elegida por el usuario (se guarda en el teléfono).
/// Permite cambiar de red (p. ej. en la exposición) sin recompilar la app.
class ServerSettings {
  static const String _key = 'server_url';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Dirección guardada, o null si se usa la predeterminada.
  Future<String?> readCustom() => _storage.read(key: _key);

  Future<String> current() async => (await readCustom()) ?? ApiConfig.baseUrl;

  Future<void> save(String url) => _storage.write(key: _key, value: url);

  Future<void> reset() => _storage.delete(key: _key);

  /// Devuelve la dirección normalizada (con http:// y sin "/" final) o null si no es válida.
  static String? normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return url;
  }
}

final serverSettingsProvider = Provider<ServerSettings>((ref) => ServerSettings());
