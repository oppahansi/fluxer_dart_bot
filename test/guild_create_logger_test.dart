import 'package:fluxer_dart/fluxer_dart.dart';
import 'package:fluxer_dart_bot/commands/guild_create_logger.dart';
import 'package:test/test.dart';

final class _RecordingLogger extends Logger {
  final entries = <(LogLevel, String)>[];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    entries.add((level, message));
  }
}

void main() {
  test(
    'handleGuildCreate logs the guild name and member/role counts at INFO',
    () {
      final logger = _RecordingLogger();
      final event = GuildCreateEvent(
        const Guild(
          id: Snowflake(1),
          name: 'Test Guild',
          icon: null,
          ownerId: Snowflake(2),
          roles: [],
          memberCount: 5,
          onlineCount: null,
          vanityUrlCode: null,
        ),
      );

      handleGuildCreate(event, logger);

      expect(logger.entries, hasLength(1));
      expect(logger.entries.single.$1, LogLevel.info);
      expect(logger.entries.single.$2, contains('Test Guild'));
      expect(logger.entries.single.$2, contains('5 members'));
    },
  );
}
