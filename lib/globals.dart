import 'package:github/github.dart';
import 'package:logging/logging.dart';

abstract class Constants {
  static const kApiVersionFile = 'api_version.txt';
  static const kClientVersionFile = 'client_version.txt';
}

abstract class Globals {
  static final github = GitHub(
    auth: Authentication.withToken(Env.githubToken),
  );

  static final logger = Logger('Launcher');

  static final customEnv = <String, String>{};
}

abstract class Env {
  static const basePath = bool.hasEnvironment('BASE_PATH')
      ? String.fromEnvironment('BASE_PATH')
      : null;
  static const apiRepoOwner = String.fromEnvironment('API_OWNER');
  static const apiRepoName = String.fromEnvironment('API_REPO');

  static const clientRepoOwner = String.fromEnvironment('CLIENT_OWNER');
  static const clientRepoName = String.fromEnvironment('CLIENT_REPO');

  static const githubToken = String.fromEnvironment('GITHUB_TOKEN');
}
