import 'dart:io';

import 'package:ivc_launcher/globals.dart';
import 'package:path/path.dart' as p;

Future<void> startApp() => switch (Platform.operatingSystem) {
      'linux' => _startLinux(),
      'windows' => _startWindows(),
      _ => throw Exception('Unsupported Platform ${Platform.operatingSystem}'),
    };

Future<void> _startLinux() async {
  final serverExe = Globals.executables['api']!;
  Process.runSync('chmod', ['u+x', serverExe]);

  await Process.start(
    'xterm',
    ['-hold', '-e', serverExe],
    environment: Globals.customEnv,
    workingDirectory: p.dirname(serverExe),
    runInShell: true,
    mode: ProcessStartMode.detached,
  );

  final clientExe = Globals.executables['client']!;
  Process.runSync('chmod', ['u+x', clientExe]);
  Process.start(
    clientExe,
    [],
    mode: ProcessStartMode.detached,
  );
  return;
}

Future<void> _startWindows() async {
  final serverExe = Globals.executables['api']!;

  final serverProc = await Process.start(
    'Start-Process',
    ['-Wait', '-FilePath', serverExe],
    environment: Globals.customEnv,
    workingDirectory: p.dirname(serverExe),
    runInShell: true,
  );
  ProcessSignal.sigint.watch().listen((event) {
    serverProc.kill();
    exit(event.signalNumber);
  });

  final clientExe = Globals.executables['client']!;
  Process.start(
    clientExe,
    [],
    mode: ProcessStartMode.detached,
  );
  return;
}
