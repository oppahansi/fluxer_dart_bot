import 'dart:io';

/// A minimal `.env` file loader — a handful of lines, not a dependency.
/// Reads `KEY=VALUE` pairs from [path] (default `.env`) and merges them
/// under [Platform.environment], so a real environment variable always
/// wins over the file (handy for CI, where you'd never commit a `.env`).
Map<String, String> loadEnv({String path = '.env'}) {
  final env = Map<String, String>.from(Platform.environment);
  final file = File(path);
  if (!file.existsSync()) return env;

  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separatorIndex = line.indexOf('=');
    if (separatorIndex == -1) continue;

    final key = line.substring(0, separatorIndex).trim();
    var value = line.substring(separatorIndex + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    env.putIfAbsent(key, () => value);
  }
  return env;
}
