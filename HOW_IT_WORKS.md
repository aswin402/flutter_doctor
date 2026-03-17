# Flutter Doctor - How It Works 🛠️

This document provides a comprehensive explanation of the flutter_doctor CLI system, detailing its architecture, data flow, and inner workings.

## 1. Entry Point (`bin/flutter_doctor.dart`)
- **Args Parsing:** The CLI uses the `args` package to parse flags such as `--verbose` (shows exact file:line details), `--score` (outputs only the score for CI), `--no-lint` (skips the lint runner), `--no-dead-code` (skips the dead code runner), `--diff` (scans only changed files versus a branch), and `--fix` (an AI fix mode stub).
- **Order of Execution:** 
  1. `Config.load(projectPath)` is called to load ignore rules and settings.
  2. `ProjectDetector(projectPath).detect()` gathers project metadata (Flutter/Dart version, state management, file count).
  3. `runAnalysis()` runs linting and dead code checks in parallel.
  4. `Reporter` takes the results and generates the animated terminal output.
- **Parallel Analysis:** `Future.wait(completers)` is used in `runAnalysis()`. The lint runner and dead code runner futures are added to a list (if not skipped via args or config) and awaited simultaneously, which reduces total analysis time.
- **Exit Code Behavior:** If the `--score` flag is used, it sets the exit code to `1` if the score is `< 75`, or `0` otherwise. At the end of a normal run, it also exits with `1` if the health score is strictly less than 75, making it CI-ready.

## 2. Config System (`config.dart`)
- **Lookup Order:** It looks for a configuration file first at `flutter_doctor.config.json`. If not found, it falls back to the `pubspec.yaml` file, checking for a `flutterDoctor` key.
- **Ignored Items:** You can ignore specific lint rules by rule name (e.g., `flutter/hardcoded-string`) via the `ignore > rules` array, and you can ignore specific files by glob paths via the `ignore > files` array.
- **Default Values:** By default, `lint` is set to `true`, `deadCode` is set to `true`, `ignoreRules` is an empty list `[]`, and `ignoreFiles` is an empty list `[]`.

## 3. Project Detection (`project_detector.dart`)
- **Flutter/Dart Version:** It runs the command `flutter --version` via `Process.run`. Using regex patterns (`Flutter ([\d.]+)` and `Dart ([\d.]+)`), it extracts the installed versions of Flutter and Dart from standard output.
- **State Management:** It reads the `pubspec.yaml` file natively as a string and looks for specific package keywords: `riverpod` or `hooks_riverpod` (Riverpod), `provider` (Provider), `bloc` (Bloc), and `get` (GetX).
- **Source Files Count:** It performs a recursive directory walk (`Directory(projectPath).list(recursive: true, followLinks: false)`), tracking files ending with the `.dart` extension to get the total source file count.

## 4. Lint Runner (`lint_runner.dart`)
- **Current Status:** The lint runner currently uses **mock data**, meaning no real AST parsing is performed on the source code yet.
- **Rules Checked (Mocked):**
  - `flutter/no-build-context-async` (ERR - risk of crash after widget unmounts)
  - `flutter/dispose-controllers` (ERR - memory leak)
  - `flutter/missing-const` (WARN)
  - `flutter/list-view-shrink-wrap` (WARN)
  - `flutter/rebuild-on-provider` (WARN)
  - `dart/unclosed-stream` (ERR - memory leak)
  - `flutter/missing-semantics` (WARN)
  - `flutter/hardcoded-string` (WARN)
  - `dart/nullable-without-check` (ERR)
  - `flutter/image-cache-miss` (WARN)
- **Ignore Rules Filtering:** Mock diagnostics are filtered by `!ignoreRules.contains(d['rule'])` directly against the config.
- **Data Shape Returned:** The runner returns a list of maps with the shape:
  `{ 'type': String, 'rule': String, 'location': String, 'description': String }`

## 5. Dead Code Runner (`dead_code_runner.dart`)
- **Current Status:** This runner currently uses **mock data**, instead of a real `dart analyze` JSON output.
- **Types of Dead Code Detected:**
  - `UNUSED FILE` (e.g., `lib/utils/legacy_parser.dart`)
  - `UNUSED EXPORT` (e.g., `lib/models/deprecated_user.dart → toJsonOld()`)
  - `DUPLICATE` (e.g., `lib/helpers/string_utils.dart ≈ lib/utils/text_utils.dart`)
- **Data Shape Returned:** It relies on a list of maps shaped like:
  `{ 'type': String, 'description': String }`
  *(Note: A `subType` was referenced in the reporter, but is functionally extracted as `'UNKNOWN'` because it is not actively provided by the mock data JSON).*

## 6. Scorer (`scorer.dart`)
- **Exact Formula:** The score is calculated as `100 - (errors × 3) - warnings - deadCode`. It is then clamped between `0` and `100`.
- **Score Labels:**
  - **≥ 75**: Great
  - **50 - 74**: Needs work
  - **< 50**: Critical
- **CI Exit Code Behavior:** If the score strictly drops below 75, the application issues `exit(1)` failing the CI build. Otherwise, it issues `exit(0)`.

## 7. Reporter (`reporter.dart`)
- **Output Sequence:**
  1. Print the executed command.
  2. Print project detection info.
  3. Print the animated sequence header and spinner.
  4. Print lint diagnostics (table).
  5. Print dead code diagnostics.
  6. Print the health score UI box.
  7. Print top priority fixes (top 3 `ERR` limits).
  8. Print the footer instructions (`--fix`, `--diff`).
- **ANSI Color Codes:** Utilizes explicit terminal codes (e.g., `\u001b[36m` for cyan/rule names, `\u001b[90m` for gray/boxes/locations, `\u001b[32m` for green success checks). The background color wrappers like `\u001b[41;97m` make the red ` ERR ` tags visually pop.
- **Spinner Handling:** While doing parallel analysis, a `Timer.periodic` triggers every 100ms on `stderr`, cycling through an array of visual phases `['⠋', '⠙', '⠹', ...]`. It updates via carriage return `\r` to overwrite the same line without scrolling the output.
- **Health Score Bar:** The bar calculation converts the score out of 100 to a 20-character width visual box. `filled = (score / 5).round()`. Filled blocks use `█` and empty ones use `░`.
- **TTY Detection:** The class uses `stdout.hasTerminal` via `dart:io` to identify TTY setups. If false (e.g., CI server logs), it gracefully disables ANSI color output through the `_color` wrapper.

## 8. Data Flow Diagram
```text
CLI Args ────┐
             ▼
       [ Config.load ]
             │
             ▼
   [ ProjectDetector ]
             │
             ├───► [ LintRunner.run ] ─────┐
             │                             │  (Future.wait)
             └───► [ DeadCodeRunner.run ] ─┘
                           │
                           ▼
                      [ Scorer ]
                           │
                           ▼
                     [ Reporter ]
                           │
                           ▼
                      ( stdout )
```

## 9. Current Limitations (Honest Assessment)
- **Mocked Behavior:** The lint checks do not rely on a real AST traversal or `Analyzer` hooks. The rules currently operate purely off a hardcoded mock data set natively defined inside `LintRunner`.
- **Dead Code Validation:** The dead code system returns hardcoded strings matching output specs rather than actively parsing `dart analyze` JSON output. Filtering via `ignoreFiles` glob isn't implemented (it is currently a stub).
- **The `--fix` Flag:** The `--fix` mode is entirely a visual stub at the moment. Passing `--fix` does not invoke an AI agent or apply code changes.
- **Missing `subType` Handling:** The dead code mock structure does not explicitly provide the `subType` key expected by the reporter, causing it to default to `UNKNOWN`.
- **Hardcoded File References:** The mock data points to paths like `lib/screens/profile.dart` which presumably don't exist dynamically across every project run.

## 10. How to Extend
- **How to add a new lint rule:**
  1. Determine the logic and type needed (ERR/WARN).
  2. Eventually inject a custom `Visitor` in a real `Analyzer` setup to traverse elements. For now, add a map entry in the `LintRunner`'s `diagnostics` array: `{ 'type': 'WARN', 'rule': 'my-custom/rule-name', 'location': '...', 'description': '...' }`
- **How to replace mock with real `dart analyze` JSON:**
  1. In `DeadCodeRunner`, use `Process.run('dart', ['analyze', '--format=json'])`.
  2. Parse the underlying stdout JSON using `dart:convert`.
  3. Map the elements over to the internal diagnostic `{ type, description }` map returned by the runner.
- **How to add a new CLI flag:**
  1. Open `bin/flutter_doctor.dart`.
  2. Add the flag definition inside `ArgParser`: `..addFlag('my-flag', help: 'Does X task')`.
  3. Extract it during execution via `results['my-flag'] as bool`.
  4. Pass the variable into the `Reporter`, `Config`, or specific runner where the conditional logic applies.
