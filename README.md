# Flutter Doctor 🚀

**Dart CLI tool that analyzes Flutter projects and generates rich animated terminal health reports.**

## Current Status: Phase 1 Complete
**Phase 1 (mock diagnostics + full terminal UI) is complete.** The project currently renders a beautifully animated terminal report, but the underlying static analysis relies strictly on mock data. Real AST parsing and live `dart analyze` integration are planned for Phase 2.

## What We've Built

- **Animated terminal output** with spinners, progress bars, and ANSI colors (gracefully degraded in non-TTY CI environments).
- **Lint diagnostics** table indicating ERR (red) / WARN (yellow), rule names (cyan), and file paths (gray).
- **Dead code detection** highlighting unused files, exports, and duplicates.
- **Health score box** with box-drawing chars, dynamic bar fill, color-coded health labels, and scoring formula `100 - (ERR×3 + WARN + DEAD)`.
- **CLI flags** `--verbose`, `--score`, `--no-lint`, `--no-dead-code`, `--diff`, `--fix` (stub), and `--no-md`.
- **NEEDEDFIX.md generation** automatically creates a report for AI agents to fix issues.
- **Config parser** capable of reading ignored rules and files from `flutter_doctor.config.json` or `pubspec.yaml:flutterDoctor`.
- **CI ready** exit 1 if the overall score drops below 75.

## How to use

### How to run on your Flutter project

To run the tool directly from source:
```bash
cd your_flutter_project
dart run /path/to/flutter_doctor/bin/flutter_doctor.dart . --verbose
```

Alternatively, you can activate it globally via path:
```bash
dart pub global activate --source path /path/to/flutter_doctor
flutter_doctor . --verbose
```

### Flags

```bash
flutter_doctor .                      # full report
flutter_doctor . --verbose            # file:line details
flutter_doctor . --score              # JSON score for CI
flutter_doctor . --no-lint            # skip linting pass
flutter_doctor . --no-dead-code       # skip dead code pass
flutter_doctor . --no-md --verbose      # skip NEEDEDFIX.md generation
flutter_doctor . --diff main          # scan changed files only (stub)
flutter_doctor . --fix                # AI fix mode (stub)
```

### AI Agent Workflow

`flutter_doctor` automatically generates a `NEEDEDFIX.md` file in your project root. You can provide this file to an AI agent to fix all issues:

1. Run `flutter_doctor . --verbose`
2. Open `NEEDEDFIX.md` and copy the "Priority Fixes" section
3. Paste it to your AI agent with: "Read NEEDEDFIX.md and fix all issues"

**Note:** Add `NEEDEDFIX.md` to your `.gitignore`:
```text
# flutter_doctor
NEEDEDFIX.md
```

## Config Example

`flutter_doctor.config.json`:

```json
{
  "lint": true,
  "deadCode": true,
  "ignore": {
    "rules": ["flutter/hardcoded-string"],
    "files": ["lib/generated/**", "**/*.g.dart"]
  }
}
```

## Code Structure & Purpose

```text
flutter_doctor/
├── bin/flutter_doctor.dart       # CLI entry, args parser, task orchestration
├── lib/src/
│   ├── analyzer/
│   │   ├── project_detector.dart # Fetches Flutter version, state mgmt, file count
│   │   ├── lint_runner.dart      # Currently serves MOCK ERR/WARN diagnostics
│   │   └── dead_code_runner.dart # Currently serves MOCK unused/duplicate code info
│   ├── reporter.dart             # ANSI spinner, tables, and color UI formatting
│   ├── scorer.dart               # Contains the score formula and bounds clamping
│   └── config.dart               # Parses JSON/YAML configuration and ignores
├── pubspec.yaml                  # Contains analyzer, args, glob, yaml, path deps
└── README.md                     # This file
```

## Known Issues (Honest Limitations)
- **Mock Diagnostics:** Both the `LintRunner` and `DeadCodeRunner` produce completely hardcoded mock data. They do not analyze your true project code yet.
- **No `--fix` functionality:** The AI `--fix` flag is purely a CLI parsing stub and does not manipulate source files.
- **No `--diff` functionality:** The branch differential flag does not actively read `git diff`.
- **Missing `subType` processing:** Dead code lists display `UNKNOWN` because the mock JSON structures lack the required key natively mapped in the `Reporter`.
- **Stubbed glob filtering:** `ignoreFiles` glob exclusion operates implicitly as a stub that does not actively purge diagnostics.

## Development / Extend

1. **Real Rules:** Replace `lint_runner.dart` mocks with actual analyzer Resolver/Visitor traversals.
   ```dart
   var unit = parseCompilationUnit(content);
   for (var node in unit.declarations) { ... }
   ```
2. **Dead Code:** Connect `Process.run('dart', ['analyze', '--format=json'])` inside `dead_code_runner.dart`.
3. **--diff:** Add `git diff --name-only $base` integration parsing.

See [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) for deeper technical documentation and architecture blueprints.

## Installation

### Option 1 — Compile to native binary (recommended)
git clone https://github.com/yourname/flutter_doctor
cd flutter_doctor
./tool/activate.sh

# Add to PATH if not already
export PATH="$PATH:$HOME/.local/bin"

### Option 2 — dart pub global (may show resolver logs on first run)
dart pub global activate flutter_doctor

---

this project is inspired by [github](https://github.com/millionco/react-doctor) project by millionco 