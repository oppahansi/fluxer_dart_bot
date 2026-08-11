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
  final bot = Bot(
    token: token,
    logger: const PrintLogger(minLevel: LogLevel.info),
    restBaseUrl: restBaseUrlString == null
        ? null
        : Uri.parse(restBaseUrlString),
  );

  bot.connectionStateChanges.listen((state) => print('[state] $state'));
  bot.onReady.listen((event) {
    print(
      'Ready — logged in as ${event.user.username} (session ${event.sessionId})',
    );
  });
  bot.onGuildCreate.listen(handleGuildCreate);
  bot.onMessageCreate.listen((event) => handlePingCommand(bot, event));

  print('Logging in...');
  await bot.login();
  print('login() returned, connection state: ${bot.connectionState}');

  // Keep the process alive; login() only awaits the initial connect(),
  // not the connection's lifetime.
  await ProcessSignal.sigint.watch().first;
  print('Shutting down...');
  await bot.dispose();
}
