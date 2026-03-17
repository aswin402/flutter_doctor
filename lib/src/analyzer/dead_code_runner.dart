import 'dart:io';
import 'package:path/path.dart' as p;

class DeadCodeRunner {
  final String projectPath;
  final List<String> ignoreFiles;

  DeadCodeRunner(this.projectPath, this.ignoreFiles);

  Future<List<Map<String, String>>> run() async {
    final diagnostics = <Map<String, String>>[];
    try {
      final libDir = Directory(p.join(projectPath, 'lib'));
      if (!await libDir.exists()) return diagnostics;

      final dartFiles = <String>[];
      await for (final entity
          in libDir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (entity.path.endsWith('.g.dart')) continue;
          if (entity.path.endsWith('.freezed.dart')) continue;
          if (entity.path.contains('generated')) continue;
          dartFiles.add(entity.path);
        }
      }

      final importedPaths = <String>{};
      for (final file in dartFiles) {
        try {
          final content = await File(file).readAsString();
          final matches =
              RegExp(r"""import\s+['"]([^'"]+)['"]""").allMatches(content);
          for (final m in matches) {
            importedPaths.add(m.group(1)!);
          }
        } catch (_) {}
      }

      for (final file in dartFiles) {
        final rel = file
            .replaceAll('$projectPath/', '')
            .replaceAll('$projectPath\\', '');
        if (rel == 'lib/main.dart') continue;
        final ignored = ignoreFiles.any((pat) =>
            rel.contains(pat.replaceAll('**/', '').replaceAll('*', '')));
        if (ignored) continue;
        final fileName = p.basename(file);
        final shortPath = rel.replaceFirst('lib/', '');
        final isImported = importedPaths.any(
            (imp) => imp.endsWith(fileName) || imp.contains(shortPath));
        if (!isImported) {
          diagnostics.add({
            'type': 'DEAD',
            'subType': 'UNUSED FILE',
            'description': rel,
          });
        }
      }

      // detect duplicate filenames across directories
      final byName = <String, List<String>>{};
      for (final file in dartFiles) {
        final name = p.basename(file);
        final rel = file
            .replaceAll('$projectPath/', '')
            .replaceAll('$projectPath\\', '');
        byName.putIfAbsent(name, () => []).add(rel);
      }
      for (final entry in byName.entries) {
        if (entry.value.length > 1) {
          diagnostics.add({
            'type': 'DEAD',
            'subType': 'DUPLICATE',
            'description': entry.value.join(' ≈ '),
          });
        }
      }
    } catch (_) {}
    return diagnostics;
  }
}