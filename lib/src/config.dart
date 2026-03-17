import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class Config {
  final bool lint;
  final bool deadCode;
  final List<String> ignoreRules;
  final List<String> ignoreFiles;

  Config({
    this.lint = true,
    this.deadCode = true,
    this.ignoreRules = const [],
    this.ignoreFiles = const [],
  });

  static Future<Config> load(String projectPath) async {
    final configFile = File(p.join(projectPath, 'flutter_doctor.config.json'));
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));

    Map<String, dynamic> configMap = {};

    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      configMap = json.decode(content) as Map<String, dynamic>;
    } else if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      final yamlMap = loadYaml(content);
      final flutterDoctor = yamlMap['flutterDoctor'];
      if (flutterDoctor != null) {
        configMap = Map<String, dynamic>.from(flutterDoctor as Map);
      }
    }

    final ignore =
        configMap['ignore'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rules =
        (ignore['rules'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final files =
        (ignore['files'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    return Config(
      lint: configMap['lint'] as bool? ?? true,
      deadCode: configMap['deadCode'] as bool? ?? true,
      ignoreRules: rules,
      ignoreFiles: files,
    );
  }
}
