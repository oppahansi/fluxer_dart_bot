import 'dart:io';

import 'package:fluxer/fluxer.dart';
import 'package:fluxer_dart_bot/commands/guild_create_logger.dart';
import 'package:fluxer_dart_bot/commands/ping_command.dart';
import 'package:fluxer_dart_bot/env.dart';

Future<void> main() async {
  final env = loadEnv();
  final token = env['FLUXER_BOT_TOKEN'];
  if (token == null || token.isEmpty) {
    stderr.writeln(
      'FLUXER_BOT_TOKEN is not set. Copy .env.example to .env and fill it in, or export it directly.',
    );
    exitCode = 1;
    return;
  }

  final restBaseUrlString = env['FLUXER_REST_BASE_URL'];
  final logger = const PrintLogger(minLevel: LogLevel.info);
  final bot = Bot(
    token: token,
    logger: logger,
    restBaseUrl: restBaseUrlString == null
        ? null
        : Uri.parse(restBaseUrlString),
  );

  // Not `.listen(...)`: an exception thrown inside a handler — a bug in
  // your own command code, most commonly — would otherwise be an
  // unhandled error that can bring the whole process down. Dart can't
  // make this automatic the way discord.py's dispatch loop does (there's
  // no way for a Stream to intercept what happens inside a caller's own
  // .listen() callback), so `.listenSafely()` is the opt-in fix: it logs
  // via the same Logger instead, and keeps the bot running.
  bot.onGuildCreate.listenSafely(
    (event) => handleGuildCreate(event, logger),
    logger: logger,
    context: 'onGuildCreate',
  );
  bot.onMessageCreate.listenSafely(
    (event) => handlePingCommand(bot, event),
    logger: logger,
    context: 'onMessageCreate',
  );

  // Connection lifecycle (Connecting/Identifying/Connected/READY/...) is
  // already logged at INFO by fluxer_gateway itself via the same `logger`
  // — nothing to print here for that.
  await bot.login();

  // Keep the process alive; login() only awaits the initial connect(),
  // not the connection's lifetime.
  await ProcessSignal.sigint.watch().first;
  logger.info('Shutting down...');
  await bot.dispose();
}
