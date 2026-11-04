import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/padalab_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  runApp(const PadalabApp());
}
