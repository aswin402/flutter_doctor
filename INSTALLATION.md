Once installed globally via `./tool/activate.sh`, just run it from anywhere:

**Basic usage in any Flutter project:**
```bash
# go to any flutter project
cd /path/to/your/flutter/project

# scan current directory
flutter_doctor .

# with verbose output
flutter_doctor . --verbose

# score only (for CI)
flutter_doctor . --score
```

**Or pass the path directly from anywhere:**
```bash
flutter_doctor /home/aswin/programming/vscode/flutter/secutest6
flutter_doctor /home/aswin/programming/vscode/flutter/secutest6 --verbose
flutter_doctor /home/aswin/programming/vscode/flutter/secutest6 --score
```

**All available flags:**
```bash
flutter_doctor . --verbose      # show file:line for each issue
flutter_doctor . --score        # print score number only
flutter_doctor . --no-lint      # skip lint, only dead code
flutter_doctor . --no-dead-code # skip dead code, only lint
flutter_doctor . --diff main    # scan only files changed vs main branch
flutter_doctor . --fix          # AI fix mode (coming soon)
flutter_doctor . --help         # show all flags
```

**Add config to ignore specific rules in a project:**
```bash
# inside any flutter project create this file
cat > flutter_doctor.config.json << 'EOF'
{
  "ignore": {
    "rules": ["deprecated_member_use"],
    "files": ["lib/generated/**", "**/*.g.dart"]
  }
}
EOF

flutter_doctor . --verbose
# deprecated_member_use will not appear
```

**Add to CI/CD — `.github/workflows/flutter_doctor.yml`:**
```yaml
name: Flutter Doctor
on: [pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: dart-lang/setup-dart@v1
      
      - name: Install flutter_doctor
        run: |
          git clone https://github.com/yourname/flutter_doctor /tmp/flutter_doctor
          cd /tmp/flutter_doctor
          ./tool/activate.sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Run flutter_doctor
        run: flutter_doctor . --score
        # exits with code 1 if score < 75, failing the CI check
```

**Shortcut — add alias to `~/.zshrc` for even faster usage:**
```bash
echo 'alias fd="flutter_doctor"' >> ~/.zshrc
source ~/.zshrc

# now use fd instead of flutter_doctor
fd . --verbose
fd /path/to/project --score
```