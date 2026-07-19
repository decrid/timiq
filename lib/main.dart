import 'package:flutter/material.dart';

import 'app/timiq_app.dart';
import 'application/timiq_controller.dart';
import 'data/timiq_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TimiqController(repository: SqliteTimiqRepository());
  await controller.initialize();
  runApp(TimiqApp(controller: controller));
}
