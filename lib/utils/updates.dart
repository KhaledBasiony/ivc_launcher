import 'dart:async';

import 'package:ivc_launcher/github_service.dart';
import 'package:ivc_launcher/globals.dart';
import 'package:ivc_launcher/utils/launch_env.dart';

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
