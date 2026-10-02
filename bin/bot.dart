import 'dart:io';

import 'package:fluxer_dart/fluxer_dart.dart';
import 'package:fluxer_dart_bot/commands/announce_command.dart';
import 'package:fluxer_dart_bot/commands/auditlog_command.dart';
import 'package:fluxer_dart_bot/commands/ban_command.dart';
import 'package:fluxer_dart_bot/commands/channel_command.dart';
import 'package:fluxer_dart_bot/commands/embed_command.dart';
import 'package:fluxer_dart_bot/commands/emoji_command.dart';
import 'package:fluxer_dart_bot/commands/guild_create_logger.dart';
import 'package:fluxer_dart_bot/commands/help_command.dart';
import 'package:fluxer_dart_bot/commands/instance_command.dart';
import 'package:fluxer_dart_bot/commands/invite_command.dart';
import 'package:fluxer_dart_bot/commands/kick_command.dart';
import 'package:fluxer_dart_bot/commands/members_command.dart';
import 'package:fluxer_dart_bot/commands/membersearch_command.dart';
import 'package:fluxer_dart_bot/commands/moderation_logger.dart';
import 'package:fluxer_dart_bot/commands/permission_command.dart';
import 'package:fluxer_dart_bot/commands/pin_command.dart';
import 'package:fluxer_dart_bot/commands/ping_command.dart';
import 'package:fluxer_dart_bot/commands/pins_update_logger.dart';
import 'package:fluxer_dart_bot/commands/presence_command.dart';
import 'package:fluxer_dart_bot/commands/purge_command.dart';
import 'package:fluxer_dart_bot/commands/react_command.dart';
import 'package:fluxer_dart_bot/commands/reaction_add_logger.dart';
import 'package:fluxer_dart_bot/commands/reactions_command.dart';
import 'package:fluxer_dart_bot/commands/refresh_urls_command.dart';
import 'package:fluxer_dart_bot/commands/reply_command.dart';
import 'package:fluxer_dart_bot/commands/role_command.dart';
import 'package:fluxer_dart_bot/commands/serverinfo_command.dart';
import 'package:fluxer_dart_bot/commands/setup_command.dart';
import 'package:fluxer_dart_bot/commands/setup_on_join.dart';
import 'package:fluxer_dart_bot/commands/slowmode_command.dart';
import 'package:fluxer_dart_bot/commands/sticker_command.dart';
import 'package:fluxer_dart_bot/commands/timeout_command.dart';
import 'package:fluxer_dart_bot/commands/typing_command.dart';
import 'package:fluxer_dart_bot/commands/upload_command.dart';
import 'package:fluxer_dart_bot/commands/userinfo_command.dart';
import 'package:fluxer_dart_bot/commands/webhook_command.dart';
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
    bot.onMessageReactionAdd.listen(
      (event) => handleMessageReactionAdd(event, logger),
    );
    bot.onGuildMemberAdd.listen(
      (event) => handleGuildMemberAddSetupPrompt(event, bot),
    );
    bot.onChannelPinsUpdate.listen(
      (event) => handleChannelPinsUpdate(event, bot, logger),
    );
    registerModerationLoggers(bot, logger);

    final commands = CommandRouter(bot: bot, prefix: '!')
      ..command(
        'ping',
        handlePing,
        middleware: [cooldown(Duration(seconds: 5))],
      )
      ..command('embed', handleEmbed)
      ..command('reply', handleReply)
      ..command('react', handleReact)
      ..command(
        'purge',
        handlePurge,
        middleware: [requireGuildPermission(PermissionFlag.manageMessages)],
      )
      ..command(
        'channel',
        handleChannel,
        middleware: [requireGuildPermission(PermissionFlag.manageChannels)],
      )
      ..command(
        'slowmode',
        handleSlowmode,
        middleware: [requireGuildPermission(PermissionFlag.manageChannels)],
      )
      ..command(
        'permission',
        handlePermission,
        middleware: [requireGuildPermission(PermissionFlag.manageRoles)],
      )
      ..command(
        'kick',
        handleKick,
        middleware: [requireGuildPermission(PermissionFlag.kickMembers)],
      )
      ..command(
        'ban',
        handleBan,
        middleware: [requireGuildPermission(PermissionFlag.banMembers)],
      )
      ..command(
        'unban',
        handleUnban,
        middleware: [requireGuildPermission(PermissionFlag.banMembers)],
      )
      ..command(
        'timeout',
        handleTimeout,
        middleware: [requireGuildPermission(PermissionFlag.moderateMembers)],
      )
      ..command(
        'role',
        handleRole,
        middleware: [requireGuildPermission(PermissionFlag.manageRoles)],
      )
      ..command(
        'auditlog',
        handleAuditLog,
        middleware: [requireGuildPermission(PermissionFlag.viewAuditLog)],
      )
      ..command(
        'emoji',
        handleEmoji,
        middleware: [requireGuildPermission(PermissionFlag.createExpressions)],
      )
      ..command(
        'sticker',
        handleSticker,
        middleware: [requireGuildPermission(PermissionFlag.createExpressions)],
      )
      ..command(
        'webhook',
        handleWebhook,
        middleware: [requireGuildPermission(PermissionFlag.manageWebhooks)],
      )
      ..command(
        'invite',
        handleInvite,
        middleware: [
          requireGuildPermission(PermissionFlag.createInstantInvite),
        ],
      )
      ..command(
        'pin',
        handlePin,
        middleware: [requireGuildPermission(PermissionFlag.pinMessages)],
      )
      ..command(
        'unpin',
        handleUnpin,
        middleware: [requireGuildPermission(PermissionFlag.pinMessages)],
      )
      ..command('pins', handlePins)
      ..command('typing', handleTyping)
      ..command('upload', handleUpload)
      ..command('reactors', handleReactors)
      ..command(
        'clearreactions',
        handleClearReactions,
        middleware: [requireGuildPermission(PermissionFlag.manageMessages)],
      )
      ..command('presence', handlePresence)
      ..command('userinfo', handleUserInfo)
      ..command('membersearch', handleMemberSearch)
      ..command('instance', handleInstance)
      ..command(
        'announce',
        handleAnnounce,
        middleware: [requireGuildPermission(PermissionFlag.manageChannels)],
      )
      ..command(
        'follow',
        handleFollow,
        middleware: [requireGuildPermission(PermissionFlag.manageWebhooks)],
      )
      ..command('publish', handlePublish)
      ..command('source', handleCrosspostSource)
      ..command('refreshurls', handleRefreshUrls)
      ..command('serverinfo', handleServerInfo)
      ..command('members', handleMembers)
      ..command('setup', handleSetup);
    commands.command('help', helpCommand(commands));

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
