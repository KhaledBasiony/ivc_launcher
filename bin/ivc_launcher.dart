import 'dart:async';

import 'package:ivc_launcher/utils/runner.dart';
import 'package:ivc_launcher/utils/updates.dart';
import 'package:ivc_launcher/utils/launch_env.dart';
import 'package:logging/logging.dart';

void main(List<String> arguments) async {
  // Initialize.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level} @ ${record.time}: ${record.message}');
  });

  // Wait for updates.
  await Future.wait([
    tryUpdateClient(),
    tryUpdateApi(),
  ]);

  // Ensure Environment is Set before launching.
  await ensureEnvironment();

  // Launch App
  await startApp();
}
