import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initFirebase(); // solo Android; en el navegador se omite
  runApp(const ProviderScope(child: VitalGuardApp()));
}
