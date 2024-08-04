import 'dart:async';
import 'dart:io';

import 'package:ivc_launcher/github_service.dart';
import 'package:ivc_launcher/globals.dart';
import 'package:ivc_launcher/utils/launch_env.dart';

import 'package:path/path.dart' as p;

/// Update the api if the latest release doesn't match the current version.
Future<void> tryUpdateApi() async {
  await _tryUpdate(
    'Api',
    getCurrentApiVersion,
    getLatestApiVersion,
    downloadLatestApi,
  );
  Globals.executables['api'] = _getExecutablePath(Env.apiRepoName, 'server');
}

/// Update the api if the latest release doesn't match the current version.
Future<void> tryUpdateClient() async {
  await _tryUpdate(
    'Client',
    getCurrentClientVersion,
    getLatestClientVersion,
    downloadLatestClient,
  );
  Globals.executables['client'] =
      _getExecutablePath(Env.clientRepoName, 'client');
}

String _getExecutablePath(
  String dirName,
  String exeSubString,
) {
  final directory = Directory(Env.basePath ?? p.current)
      .listSync()
      .whereType<Directory>()
      .where(
        (element) => p.basename(element.path) == dirName,
      )
      .singleOrNull;

  if (directory == null) {
    Globals.logger.severe(
      'Could not find a directory with the repo name: $dirName after updating.',
    );
    throw Exception('Unable to find directory after update.');
  }

  final executable = directory
      .listSync()
      .whereType<File>()
      .where((element) => p.basename(element.path).contains(exeSubString))
      .singleOrNull;

  if (executable == null) {
    Globals.logger.severe(
      'Could not find a single executable containing "$exeSubString" in its name inside the directory: ${directory.absolute.path}',
    );
    throw Exception('Unable to find executable after update.');
  }

  return executable.absolute.path;
}

Future<void> _tryUpdate(
  String name,
  String? Function() getCurrentVersionCallback,
  FutureOr<String?> Function() getLatestVersionCallback,
  FutureOr<String> Function() downloadLatestCallback,
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
