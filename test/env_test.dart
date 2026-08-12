import 'dart:io';

import 'package:fluxer_dart_bot/env.dart';
import 'package:test/test.dart';

void main() {
  group('loadEnv', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fluxer_dart_bot_env_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('parses KEY=VALUE lines, skipping blanks and comments', () {
      final file = File('${tempDir.path}/.env')
        ..writeAsStringSync('''
# a comment
FLUXER_BOT_TOKEN=abc123

FLUXER_REST_BASE_URL="http://localhost/api"
''');

      final env = loadEnv(path: file.path);

      expect(env['FLUXER_BOT_TOKEN'], 'abc123');
      expect(env['FLUXER_REST_BASE_URL'], 'http://localhost/api');
    });

    test('a real environment variable wins over the file', () {
      final file = File('${tempDir.path}/.env')
        ..writeAsStringSync('PATH=should-not-win\n');

      final env = loadEnv(path: file.path);

      expect(env['PATH'], isNot('should-not-win'));
    });

    test('returns just Platform.environment when the file is missing', () {
      final env = loadEnv(path: '${tempDir.path}/does-not-exist.env');
      expect(env, Platform.environment);
    });
  });
}
