import 'dart:io';

class ProjectDetector {
  final String projectPath;
  String flutterVersion = '';
  String dartVersion = '';
  String stateManagement = '';
  int sourceFileCount = 0;

  ProjectDetector(this.projectPath);

  Future<void> detect() async {
    await _detectFlutterVersion();
    await _detectStateManagement();
    await _countSourceFiles();
  }

  Future<void> _detectFlutterVersion() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final flutterMatch = RegExp(r'Flutter ([\d.]+)').firstMatch(output);
        final dartMatch = RegExp(r'Dart ([\d.]+)').firstMatch(output);
        flutterVersion = flutterMatch?.group(1) ?? 'unknown';
        dartVersion = dartMatch?.group(1) ?? 'unknown';
      }
    } catch (e) {
      flutterVersion = 'not installed';
    }
  }

  Future<void> _detectStateManagement() async {
    final pubspec = File('$projectPath/pubspec.yaml');
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      if (content.contains('riverpod') || content.contains('hooks_riverpod')) {
        stateManagement = 'Riverpod';
      } else if (content.contains('provider')) {
        stateManagement = 'Provider';
      } else if (content.contains('bloc')) {
        stateManagement = 'Bloc';
      } else if (content.contains('get')) {
        stateManagement = 'GetX';
      }
    }
  }

  Future<void> _countSourceFiles() async {
    sourceFileCount = 0;
    await for (final entity
        in Directory(projectPath).list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        sourceFileCount++;
      }
    }
  }
}
