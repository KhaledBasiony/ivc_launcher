import 'dart:io';

import 'package:ivc_launcher/globals.dart';
import 'package:path/path.dart' as p;

/// Gets the current stored api version,
/// which should reflect the currently installed version.
String? getCurrentApiVersion() => Directory(p.current)
    .listSync(followLinks: false)
    .whereType<File>()
    .where((element) => p.basename(element.path) == Constants.kApiVersionFile)
    .firstOrNull
    ?.readAsStringSync()
    .trim();

/// Gets the current stored client version,
/// which should reflect the currently installed version.
String? getCurrentClientVersion() => Directory(p.current)
    .listSync(followLinks: false)
    .whereType<File>()
    .where(
        (element) => p.basename(element.path) == Constants.kClientVersionFile)
    .firstOrNull
    ?.readAsStringSync()
    .trim();

/// Prepares the environment variables, file, and directories necessary to launch the application.
void prepareEnv() => throw UnimplementedError();

/// Starts the application.
void launchApp() async => throw UnimplementedError();
