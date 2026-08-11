import 'dart:io';

import 'package:fluxer_dart/fluxer_dart.dart';
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

  // runGuarded wraps everything below in a Zone that routes uncaught
  // errors — including exceptions inside the plain .listen() callbacks
  // below, a bug in your own command code being the usual case — through
  // `logger` instead of crashing the process. This has to wrap the whole
  // program from here down, not just bot.login(): the Zone only protects
  // code that runs causally within it, and .listen() binds its callback
  // to whatever Zone was active when .listen() itself was called.
  await runGuarded(() async {
    final bot = Bot(
      token: token,
      logger: logger,
      restBaseUrl: restBaseUrlString == null
          ? null
          : Uri.parse(restBaseUrlString),
    );

    // Ordinary Stream.listen — no special method needed for safety, that's
    // what the runGuarded wrapper above is for.
    bot.onGuildCreate.listen((event) => handleGuildCreate(event, logger));

    final commands = CommandRouter(bot: bot, prefix: '!')
      ..command(
        'ping',
        handlePing,
        middleware: [cooldown(Duration(seconds: 5))],
      );

    // Connection lifecycle (Connecting/Identifying/Connected/READY/...) is
    // already logged at INFO by fluxer_dart_gateway itself via the same
    // `logger` — nothing to print here for that.
    await bot.login();

    // Keep the process alive; login() only awaits the initial connect(),
    // not the connection's lifetime.
    await ProcessSignal.sigint.watch().first;
    logger.info('Shutting down...');
    await commands.dispose();
    await bot.dispose();
  }, logger: logger);
}
