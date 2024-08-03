import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:github/github.dart';
import 'package:ivc_launcher/globals.dart';
import 'package:path/path.dart' as p;

// Fetch the latest api version that can be downloaded.
Future<String?> getLatestApiVersion() => _getLatestVerion(
      'Api',
      Env.apiRepoOwner,
      Env.apiRepoName,
    );

/// Fetch the latest client version that can be downloaded.
Future<String?> getLatestClientVersion() => _getLatestVerion(
      'Client',
      Env.clientRepoOwner,
      Env.clientRepoName,
    );

/// Downloads the latest api version to current application directory.
void downloadLatestApi({String? path}) async => _downloadLatestVersion(
      Env.apiRepoOwner,
      Env.apiRepoName,
      Constants.kApiVersionFile,
    );

/// Downloads the latest client version to current application directory.
void downloadLatestClient({String? path}) async => _downloadLatestVersion(
      Env.clientRepoOwner,
      Env.clientRepoName,
      Constants.kClientVersionFile,
    );

/// Check whether there is a new version of this launcher.
void checkSelfUpdate() async => throw UnimplementedError();

/// Update the launcher itself.
void selfUpdate() async => throw UnimplementedError();

Future<String?> _getLatestVerion(
  String name,
  String owner,
  String repo,
) async {
  final release = await _tryCallback(() => _getLatestRelease(owner, repo));

  if (release == null) {
    Globals.logger.severe(
      'Warning! could not receive the latest $name release',
    );
  }

  return release?.tagName;
}

void _downloadLatestVersion(
  String owner,
  String repo,
  String versionFileName, {
  String? basePath,
}) async {
  basePath ??=
      bool.hasEnvironment('DEBUG') ? p.join(p.current, 'binary') : p.current;
  final release = await _getLatestRelease(owner, repo);

  release.assets
      ?.where((element) => element.name!.contains(Platform.operatingSystem))
      .forEach((element) {
    Globals.logger.info('Downloading ${element.name}, size: ${element.size}');

    Globals.github.request(
      'GET',
      'repos/$owner/$repo/releases/assets/${element.id!}',
      headers: {'Accept': 'application/octet-stream'},
    ).then((value) {
      Globals.logger.info('Downloaded file ${element.name}\nExtracting..');

      print(p.extension(element.name!));
      if (p.extension(element.name!) == '.zip') {
        extractArchiveToDisk(
          ZipDecoder().decodeBytes(value.bodyBytes),
          p.join(basePath!, '${repo}_zip'),
        );
      } else if (p.extension(element.name!, 2) == '.tar.gz') {
        extractArchiveToDisk(
            TarDecoder()
                .decodeBytes(GZipDecoder().decodeBytes(value.bodyBytes)),
            p.join(basePath!, '${repo}_tar'));
      } else {
        File(p.join(basePath!, element.name!))
            .writeAsBytesSync(value.bodyBytes);
      }
    });

    File(p.join(basePath!, versionFileName))
        .writeAsStringSync(release.tagName!);
  });
}

Future<Release> _getLatestRelease(String owner, String repo) =>
    Globals.github.repositories.getLatestRelease(RepositorySlug(owner, repo));

Future<T?> _tryCallback<T>(FutureOr<T> Function() callback) async {
  try {
    return await callback();
  } catch (e) {
    return null;
  }
}
