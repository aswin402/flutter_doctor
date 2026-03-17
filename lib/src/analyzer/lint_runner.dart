import 'dart:convert';
import 'dart:io';

class LintRunner {
  final String projectPath;
  final List<String> ignoreRules;

  LintRunner(this.projectPath, this.ignoreRules);

  Future<List<Map<String, String>>> run() async {
    final diagnostics = <Map<String, String>>[];
    try {
      final result = await Process.run(
        'dart',
        ['analyze', '--format=json', projectPath],
        workingDirectory: projectPath,
        runInShell: true,
      );
      final out = result.stdout as String;
      if (out.trim().isEmpty) return diagnostics;
      Map<String, dynamic> data;
      try {
        data = jsonDecode(out) as Map<String, dynamic>;
      } catch (_) {
        return diagnostics;
      }
      final issues = data['diagnostics'] as List<dynamic>? ?? [];
      for (final issue in issues) {
        try {
          final severity = issue['severity'] as String;
          final code = issue['code'] as String;
          final message = issue['problemMessage'] as String;
          final location = issue['location'] as Map<String, dynamic>;

          // fix absolute path → relative
          var filePath = location['file'] as String;
          final normalizedProject = projectPath.endsWith('/')
              ? projectPath
              : '$projectPath/';
          if (filePath.startsWith(normalizedProject)) {
            filePath = filePath.substring(normalizedProject.length);
          } else if (filePath.contains('/lib/')) {
            filePath = 'lib/' + filePath.split('/lib/').last;
          }

          final range = location['range'] as Map<String, dynamic>;
          final start = range['start'] as Map<String, dynamic>;
          final line = start['line'];

          if (ignoreRules.contains(code)) continue;

          diagnostics.add({
            'type': severity == 'ERROR' ? 'ERR' : 'WARN',
            'rule': code,
            'location': '$filePath:$line',
            'description': message,
          });
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      diagnostics.add({
        'type': 'WARN',
        'rule': 'analyze-failed',
        'location': projectPath,
        'description': '$e',
      });
    }
    return diagnostics;
  }
}