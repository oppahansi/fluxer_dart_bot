import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs the bulk updates a reorder produces, and changes to this bot's
/// own user.
///
/// A channel reorder arrives as `CHANNEL_UPDATE_BULK` carrying every
/// channel of the guild, sometimes twice for one reorder; a role reorder
/// or hoist change as `GUILD_ROLE_UPDATE_BULK` carrying only the roles
/// that changed. [Bot] already applies the channel ones to its cache, so
/// nothing here has to.
void registerLayoutLoggers(Bot bot, Logger logger) {
  bot.onChannelUpdateBulk.listen((event) {
    final order = [...event.channels]
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    logger.info(
      'Channels reordered in ${event.guildId}: '
      '${order.map((c) => '${c.name}@${c.position}').join(', ')}',
    );
  });

  bot.onGuildRoleUpdateBulk.listen((event) {
    logger.info(
      'Roles changed in ${event.guildId}: '
      '${event.roles.map((r) => '${r.name}@${r.position}').join(', ')}',
    );
  });

  bot.onUserUpdate.listen((event) {
    logger.info('This bot\'s user changed: ${event.user.username}');
  });
}
