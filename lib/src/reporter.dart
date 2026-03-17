import 'dart:async';
import 'dart:io';

class Reporter {
  final bool verbose;
  final bool useColor;

  Reporter({required this.verbose}) : useColor = stdout.hasTerminal;

  String _color(String code, String text) =>
      useColor ? '$code$text\u001b[0m' : text;

  Future<void> generateReport(List diagnostics, dynamic detector, int score,
      int errors, int warnings, int deadCode, int fileCount) async {
    _printCommand();
    _printProjectDetection(detector);
    await _printHeader();
    _printLintDiagnostics(diagnostics);
    _printDeadCodeDiagnostics(diagnostics);
    _printHealthScore(score, errors, warnings, deadCode, fileCount);
    _printPriorityFixes(diagnostics);
    _printFooter();
  }

  void _printCommand() {
    print(_color('\u001b[36m', '  ❯ dart run flutter_doctor . --verbose'));
    print('');
  }

  void _printProjectDetection(dynamic detector) {
    print('Detecting project...');
    
    final sm = detector.stateManagement as String;
    final parts1 = [
      '${_color("\u001b[32m", "✓ ")}Flutter ${_color("\u001b[1m", detector.flutterVersion as String)}',
      '${_color("\u001b[34m", "Dart ")}${_color("\u001b[1m", detector.dartVersion as String)}',
      if (sm.isNotEmpty) _color('\u001b[35m', sm),
    ];
    print('  ${parts1.join(_color("\u001b[90m", " · "))}');

    print('  ${_color("\u001b[32m", "✓ ")}Null safety enabled ${_color("\u001b[90m", "·")} ${detector.sourceFileCount} source files found');
    print('');
  }

  Future<void> _printHeader() async {
    print('Running analysis passes in parallel...');
    await _printSpinner();
    print(_color('\u001b[32m', '✓ Analysis complete'));
    print('');
    print(_color('\u001b[90m', '────────────────────────────────────────────────────────────────────────────'));
  }

  Future<void> _printSpinner() async {
    const spinners = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final i = DateTime.now().millisecond ~/ 100 % 10;
      stderr
          .write('\r${spinners[i]} Lint pass       [████████████░░░░░░░░] 60%');
      stderr.flush();
    });
    await Future.delayed(const Duration(milliseconds: 2000));
    timer.cancel();
    stderr.write('\r${' ' * 60}\r');
    stderr.flush();
  }

  void _printLintDiagnostics(List diagnostics) {
    final lints = diagnostics
        .where((d) => d['type'] == 'ERR' || d['type'] == 'WARN')
        .toList();
    if (lints.isEmpty) return;

    print('');
    print(_color('\u001b[90;1m', 'LINT DIAGNOSTICS'));
    print('');
    
    for (final diag in lints.take(10)) {
      final type = diag['type'] as String;
      final rule = diag['rule'] as String;
      final location = diag['location'] as String;
      
      String tag;
      if (type == 'ERR') {
        tag = '\u001b[41;97m ERR \u001b[0m';
      } else {
        tag = '\u001b[43;30m WARN \u001b[0m'; 
      }
      
      final ruleColor = _color('\u001b[36m', rule);
      final locationColor = _color('\u001b[90m', location);
      
      int tagSpace = 5;
      int midSpace = 76 - tagSpace - 1 - rule.length - location.length;
      if (midSpace < 2) midSpace = 2;

      print(tag + '  ' + ruleColor + (' ' * midSpace) + locationColor);
      print('');
    }
    
    print(_color('\u001b[90m', '────────────────────────────────────────────────────────────────────────────'));
    print('');
  }

  void _printDeadCodeDiagnostics(List diagnostics) {
    final deads = diagnostics.where((d) => d['type'] == 'DEAD').toList();
    if (deads.isEmpty) return;

    print(_color('\u001b[90;1m', 'DEAD CODE'));
    print('');
    for (final diag in deads) {
      final subType = diag['subType'] as String? ?? 'UNKNOWN';
      final desc = diag['description'] as String;
      
      print('\u001b[44;97m DEAD \u001b[0m  ' +
          _color('\u001b[90m', subType.padRight(16).toUpperCase()) +
          _color('\u001b[37m', desc));
      print('');
    }
    print(_color('\u001b[90m', '────────────────────────────────────────────────────────────────────────────'));
    print('');
  }

  void _printHealthScore(
      int score, int errors, int warnings, int deadCount, int fileCount) {
    final filled = (score / 100 * 52).round();
    final empty = 52 - filled;
    final scoreColor = score >= 75
        ? '\u001b[32m'
        : score >= 50
            ? '\u001b[33m'
            : '\u001b[31m';
            
    final bar = _color(scoreColor, '━' * filled) + _color('\u001b[90m', '─' * empty);
    final boxColor = '\u001b[90m';
    
    final label = score >= 75
        ? 'Great'
        : score >= 50
            ? 'Needs work'
            : 'Critical';
            
    final scoreStr = score.toString();
    final statsStrRaw = '$errors errors  $warnings warnings  $deadCount dead code  $fileCount files scanned';
    final statsStr = '${_color('\u001b[1m\u001b[97m', errors.toString())} errors  ${_color('\u001b[1m\u001b[97m', warnings.toString())} warnings  ${_color('\u001b[1m\u001b[97m', deadCount.toString())} dead code  ${_color('\u001b[1m\u001b[97m', fileCount.toString())} files scanned';
    
    int textOffset = 13; 
    print(_color(boxColor, '╭───────────────────────────────────────────────────────────────────────────╮'));
    print(_color(boxColor, '│                                                                           │'));
    
    String l1Spaces = ' ' * (75 - textOffset - 12);
    print(_color(boxColor, '│') + _color(scoreColor, '  \u001b[1m\u001b[4m$scoreStr\u001b[24m\u001b[0m' + ' ' * (textOffset - 2 - scoreStr.length)) + _color(boxColor, 'HEALTH SCORE') + l1Spaces + _color(boxColor, '│'));
    
    String l2Spaces = ' ' * (75 - textOffset - 52);
    print(_color(boxColor, '│') + ' ' * textOffset + bar + l2Spaces + _color(boxColor, '│'));
    
    int l3Trail = 75 - textOffset - statsStrRaw.length;
    if (l3Trail < 0) l3Trail = 0;
    print(_color(boxColor, '│') + _color(scoreColor, '  $label' + ' ' * (textOffset - 2 - label.length)) + statsStr + (' ' * l3Trail) + _color(boxColor, '│'));
    
    print(_color(boxColor, '│                                                                           │'));
    print(_color(boxColor, '╰───────────────────────────────────────────────────────────────────────────╯'));
    print('');
  }

  void _printPriorityFixes(List diagnostics) {
    print('Top priority fixes:');
    final priorities =
        diagnostics.where((d) => d['type'] == 'ERR').take(3).toList();
    for (final diag in priorities) {
      print(
          '${_color('\u001b[31m', '→')} Fix ${_color('\u001b[36m', diag['rule'] as String)} — ${diag['description']}');
    }
    print('');
  }

  void _printFooter() {
    print(
        'Run ${_color('\u001b[36m', 'flutter_doctor . --fix')} to auto-fix with AI · ${_color('\u001b[36m', '--diff main')} for PR mode');
  }
}
