import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import '../lib/src/analyzer/project_detector.dart';
import '../lib/src/analyzer/lint_runner.dart';
import '../lib/src/analyzer/dead_code_runner.dart';
import '../lib/src/reporter.dart';
import '../lib/src/scorer.dart';
import '../lib/src/config.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Show file:line per rule')
    ..addFlag('score', help: 'Output score only (CI)')
    ..addFlag('no-lint', negatable: false, help: 'Skip lint pass')
    ..addFlag('no-dead-code', negatable: false, help: 'Skip dead code pass')
    ..addOption('diff', help: 'Scan only changed files vs branch')
    ..addFlag('fix', negatable: false, help: 'Open AI fix mode')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error: $e');
    print(parser.usage);
    exit(1);
  }

  if (results['help'] as bool) {
    print(parser.usage);
    exit(0);
  }

  // first non-flag argument is the project path
  final positional = results.rest;
  final projectPath = positional.isNotEmpty
      ? p.normalize(positional.first)
      : p.normalize(Directory.current.path);

  if (!await Directory(projectPath).exists()) {
    stderr.writeln('Error: Project directory not found: $projectPath');
    exit(1);
  }

  // --fix stub
  if (results['fix'] as bool) {
    print('AI fix mode coming soon.');
    print('Run with --verbose to see all issues first.');
    exit(0);
  }

  // load config
  final config = await Config.load(projectPath);

  // detect project
  final detector = ProjectDetector(projectPath);
  await detector.detect();
  print('Project detected: Flutter ${detector.flutterVersion}');

  // run analysis
  final diagnostics = await runAnalysis(projectPath, results, config);

  // calculate score from real data
  final errors = diagnostics.where((d) => d['type'] == 'ERR').length;
  final warnings = diagnostics.where((d) => d['type'] == 'WARN').length;
  final deadCode = diagnostics.where((d) => d['type'] == 'DEAD').length;
  final fileCount = detector.sourceFileCount;
  final score = calculateScore(errors, warnings, deadCode);

  // --score flag: print only the number and exit
  if (results['score'] as bool) {
    stdout.writeln(score);
    exit(score < 75 ? 1 : 0);
  }

  // --diff mode stub
  if (results['diff'] != null) {
    print('Diff mode: scanning changes vs ${results['diff']}');
  }

  // generate full report
  final reporter = Reporter(verbose: results['verbose'] as bool);
  await reporter.generateReport(
      diagnostics, detector, score, errors, warnings, deadCode, fileCount);

  exit(score < 75 ? 1 : 0);
}

Future<List<dynamic>> runAnalysis(
    String projectPath, ArgResults results, Config config) async {
  final futures = <Future<List<Map<String, String>>>>[];

  if (!(results['no-lint'] as bool) && config.lint) {
    futures.add(LintRunner(projectPath, config.ignoreRules).run());
  }

  if (!(results['no-dead-code'] as bool) && config.deadCode) {
    futures.add(DeadCodeRunner(projectPath, config.ignoreFiles).run());
  }

  if (futures.isEmpty) return [];

  final all = await Future.wait(futures);
  return all.expand((r) => r).toList();
}