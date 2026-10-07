import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/server_settings.dart';
import '../core/theme/app_theme.dart';

/// Cuadro para cambiar la dirección del backend y probar la conexión.
class ServerSettingsDialog extends ConsumerStatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  ConsumerState<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _testing = false;
  bool _ok = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await ref.read(serverSettingsProvider).current();
    if (mounted) setState(() => _controller.text = url);
  }

  Future<void> _test() async {
    final url = ServerSettings.normalize(_controller.text);
    if (url == null) {
      setState(() {
        _ok = false;
        _result = 'La dirección no es válida.';
      });
      return;
    }
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get('$url/api/health');
      final up = res.statusCode == 200;
      if (mounted) {
        setState(() {
          _ok = up;
          _result = up ? 'Conexión correcta.' : 'El servidor respondió con un error.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ok = false;
          _result = 'No se pudo conectar. Revisa la dirección, que el backend esté encendido y la red.';
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = ServerSettings.normalize(_controller.text);
    if (url == null) {
      setState(() {
        _ok = false;
        _result = 'La dirección no es válida.';
      });
      return;
    }
    await ref.read(serverSettingsProvider).save(url);
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servidor guardado: $url')));
  }

  Future<void> _reset() async {
    await ref.read(serverSettingsProvider).reset();
    await _load();
    if (mounted) {
      setState(() {
        _ok = true;
        _result = 'Dirección restablecida a la predeterminada.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Servidor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección del backend de Vital Guard. En la misma Wi-Fi usa la IP de la PC, '
              'por ejemplo http://192.168.18.35:8081',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Dirección del servidor',
                hintText: 'http://192.168.18.35:8081',
              ),
            ),
            if (_testing) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 12),
              Text(
                _result!,
                style: TextStyle(
                  color: _ok ? const Color(0xFF2E7D32) : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text('Restablecer')),
        TextButton(onPressed: _testing ? null : _test, child: const Text('Probar')),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
