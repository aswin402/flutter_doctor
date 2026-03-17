int calculateScore(int errors, int warnings, int deadCode) {
  final baseScore = 100 - (errors * 3) - warnings - deadCode;
  return baseScore.clamp(0, 100);
}
