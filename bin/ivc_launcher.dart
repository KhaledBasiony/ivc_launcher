import 'dart:async';
import 'dart:io';

import 'package:ivc_launcher/github_service.dart';
import 'package:ivc_launcher/globals.dart';
import 'package:ivc_launcher/utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final customEnv = <String, String>{};

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
}

/// Update the api if the latest release doesn't match the current version.
Future<void> tryUpdateApi() => _tryUpdate(
      'Api',
      getCurrentApiVersion,
      getLatestApiVersion,
      downloadLatestApi,
    );

/// Update the api if the latest release doesn't match the current version.
Future<void> tryUpdateClient() => _tryUpdate(
      'Client',
      getCurrentClientVersion,
      getLatestClientVersion,
      downloadLatestClient,
    );

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
    'SHARED_API_KEY_FILE': p.join(secretsDir.path, 'shared_api_key'),
    'DBX_TOKEN_FILE': p.join(secretsDir.path, 'dropbox_token'),
    'PASSPHRASE_FILE': p.join(secretsDir.path, 'passphrase'),
    'API_APP_SHARED': sharedAppIdFile.readAsStringSync().trim(),
    'API_APP_DEDICATED': dedicatedAppIdFile.readAsStringSync().trim(),
  };
  customEnv.addAll(secretsFileMap);

  final cfgFile = File(p.join(basePath, '.cfg', 'config.yaml'));
  if (!cfgFile.existsSync()) {
    Globals.logger.severe('Cannot find Config file, please contact the admin.');
    throw Exception('Config not found');
  }
  customEnv['CONFIG'] = cfgFile.absolute.path;

  final dbDir = Directory(p.join(basePath, 'db'))..createSync(recursive: true);
  customEnv['DB_DIR'] = dbDir.absolute.path;

  final mediaDir = Directory(p.join(basePath, 'media'))
    ..createSync(recursive: true);
  customEnv['MEDIA_DIR'] = mediaDir.absolute.path;

  final cacheDir = Directory(p.join(basePath, 'cache'))
    ..createSync(recursive: true);
  customEnv['CACHE_DIR'] = cacheDir.absolute.path;

  final logsDir = Directory(p.join(basePath, 'logs'))
    ..createSync(recursive: true);
  customEnv['LOGS_DIR'] = logsDir.absolute.path;

  customEnv['CLIENT_ORIGIN'] = 'http://localhost:8000';
  customEnv['REALM_DISABLE_ANALYTICS'] = 'true';
}

Future<void> _tryUpdate(
  String name,
  String? Function() getCurrentVersionCallback,
  FutureOr<String?> Function() getLatestVersionCallback,
  FutureOr<void> Function() downloadLatestCallback,
) async {
  final currentVersion = getCurrentVersionCallback();
  final latestVersion = await getLatestVersionCallback();

  if (currentVersion == null) {
    if (latestVersion == null) {
      throw Exception('Cannot fetch $name release or detect current $name.');
    } else {
      await downloadLatestCallback();
      return;
    }
  } else if (latestVersion == null) {
    Globals.logger.warning(
      'Cannot fetch the latest $name version, continuing with existing version.',
    );
    return;
  } else if (latestVersion == currentVersion) {
    Globals.logger.fine('$name already at latest version $latestVersion');
    return;
  } else {
    await downloadLatestCallback();
    return;
  }
}
