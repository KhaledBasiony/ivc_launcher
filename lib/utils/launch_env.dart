import 'dart:io';

import 'package:ivc_launcher/globals.dart';
import 'package:path/path.dart' as p;

/// Gets the current stored api version,
/// which should reflect the currently installed version.
String? getCurrentApiVersion() => Directory(Env.basePath ?? p.current)
    .listSync(followLinks: false)
    .whereType<File>()
    .where((element) => p.basename(element.path) == Constants.kApiVersionFile)
    .firstOrNull
    ?.readAsStringSync()
    .trim();

/// Gets the current stored client version,
/// which should reflect the currently installed version.
String? getCurrentClientVersion() => Directory(Env.basePath ?? p.current)
    .listSync(followLinks: false)
    .whereType<File>()
    .where(
        (element) => p.basename(element.path) == Constants.kClientVersionFile)
    .firstOrNull
    ?.readAsStringSync()
    .trim();

/// Ensures the correct directory structure for the application
/// and sets the correct environment variables.
///
/// throws if necessary files are not provided.
Future<void> ensureEnvironment({String? basePath}) async {
  basePath ??= Env.basePath ?? p.current;
  Directory(basePath).createSync(recursive: true);

  final secretsDir = Directory(p.join(basePath, '.secrets')).absolute;
  if (!secretsDir.existsSync()) {
    Globals.logger
        .severe('Cannot find Secrets directory, please contact the admin.');
    throw Exception('Secrets not found');
  }
  final sharedAppIdFile = File(p.join(secretsDir.path, 'shared_app_id'));
  final dedicatedAppIdFile = File(p.join(secretsDir.path, 'dedicated_app_id'));
  if (!(sharedAppIdFile.existsSync() && dedicatedAppIdFile.existsSync())) {
    Globals.logger.severe(
        'Cannot find the Atlas App Id files, please contact the admin.');
    throw Exception('Secrets not found');
  }

  final secretsFileMap = <String, String>{
    'DEDICATED_API_KEY_FILE': p.join(secretsDir.path, 'dedicated_api_key'),
    'DEDICATED_APP_ID_FILE': dedicatedAppIdFile.path,
    'SHARED_API_KEY_FILE': p.join(secretsDir.path, 'shared_api_key'),
    'SHARED_APP_ID_FILE': sharedAppIdFile.path,
    'DBX_TOKEN_FILE': p.join(secretsDir.path, 'dropbox_token'),
    'PASSPHRASE_FILE': p.join(secretsDir.path, 'passphrase'),
    'TELEGRAM_TOKEN_FILE': p.join(secretsDir.path, 'telegram_token'),
  };
  Globals.customEnv.addAll(secretsFileMap);

  final cfgFile = File(p.join(basePath, '.cfg', 'config.yaml'));
  if (!cfgFile.existsSync()) {
    Globals.logger.severe('Cannot find Config file, please contact the admin.');
    throw Exception('Config not found');
  }
  Globals.customEnv['CONFIG'] = cfgFile.absolute.path;

  final dbDir = Directory(p.join(basePath, 'db'))..createSync(recursive: true);
  Globals.customEnv['DB_DIR'] = dbDir.absolute.path;

  final mediaDir = Directory(p.join(basePath, 'media'))
    ..createSync(recursive: true);
  Globals.customEnv['MEDIA_DIR'] = mediaDir.absolute.path;

  final cacheDir = Directory(p.join(basePath, 'cache'))
    ..createSync(recursive: true);
  Globals.customEnv['CACHE_DIR'] = cacheDir.absolute.path;

  final logsDir = Directory(p.join(basePath, 'logs'))
    ..createSync(recursive: true);
  Globals.customEnv['LOGS_DIR'] = logsDir.absolute.path;

  Globals.customEnv['CLIENT_ORIGIN'] = 'http://localhost:8000';
  Globals.customEnv['REALM_DISABLE_ANALYTICS'] = 'true';

  Globals.logger.info('Creating environment: done!');
}

/// Starts the application.
void launchApp() async => throw UnimplementedError();
