import 'package:flutter/material.dart';

import 'app/padalab_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Do not lock Android to landscape: the shared workspace supports phone
  // portrait, phone landscape, tablet and browser layouts.
  runApp(const PadalabApp());
}
