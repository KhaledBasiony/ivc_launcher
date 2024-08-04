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
Future<String> downloadLatestApi({String? path}) => _downloadLatestVersion(
      Env.apiRepoOwner,
      Env.apiRepoName,
      Constants.kApiVersionFile,
    );

/// Downloads the latest client version to current application directory.
///
/// Returns the path of the downloaded directory
Future<String> downloadLatestClient({String? path}) => _downloadLatestVersion(
      Env.clientRepoOwner,
      Env.clientRepoName,
      Constants.kClientVersionFile,
      basePath: path,
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

Future<String> _downloadLatestVersion(
  String owner,
  String repo,
  String versionFileName, {
  String? basePath,
}) async {
  basePath ??= Env.basePath ?? p.current;
  final release = await _getLatestRelease(owner, repo);

  final asset = release.assets?.firstWhere(
      (element) => element.name!.contains(Platform.operatingSystem));

  if (asset == null) {
    Globals.logger.severe(
      'No asset found for platform, Repo: $repo, Release: ${release.tagName}, OS Keyword: ${Platform.operatingSystem}',
    );
    throw Exception('Cannot find platform asset');
  }

  Globals.logger.info('Downloading ${asset.name}, size: ${asset.size}');

  final downloadedBytes = await Globals.github.request(
    'GET',
    'repos/$owner/$repo/releases/assets/${asset.id!}',
    headers: {'Accept': 'application/octet-stream'},
  ).then((value) => value.bodyBytes);
  Globals.logger.info('Downloaded file ${asset.name}\nExtracting..');

  final String resultPath;
  if (p.extension(asset.name!) == '.zip') {
    resultPath = p.join(basePath, repo);
    await extractArchiveToDisk(
      ZipDecoder().decodeBytes(downloadedBytes),
      resultPath,
    );
  } else if (p.extension(asset.name!, 2) == '.tar.gz') {
    resultPath = p.join(basePath, repo);
    await extractArchiveToDisk(
      TarDecoder().decodeBytes(GZipDecoder().decodeBytes(downloadedBytes)),
      resultPath,
    );
  } else {
    resultPath = p.join(basePath, asset.name!);
    File(resultPath).writeAsBytesSync(downloadedBytes);
  }

  File(p.join(basePath, versionFileName)).writeAsStringSync(release.tagName!);

  return resultPath;
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
