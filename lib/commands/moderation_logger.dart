import 'package:fluxer_dart/fluxer_dart.dart';

/// Wires up the event streams that have no command of their own, so the
/// example still shows what each one carries.
///
/// Several of these events deliberately carry very little: a bulk delete
/// names only ids, a webhook change names only its channel, and an emoji
/// update replaces the whole collection rather than describing a delta.
void registerModerationLoggers(Bot bot, Logger logger) {
  bot.onMessageDeleteBulk.listen((event) {
    logger.info(
      '${event.messageIds.length} messages bulk-deleted in '
      '${event.channelId}',
    );
  });

  bot.onMessageReactionRemoveAll.listen((event) {
    logger.info('All reactions cleared from ${event.messageId}');
  });

  bot.onMessageReactionRemoveEmoji.listen((event) {
    logger.info(
      '${event.emoji.name} reactions cleared from ${event.messageId}',
    );
  });

  bot.onGuildEmojisUpdate.listen((event) {
    logger.info(
      'Guild ${event.guildId} now has ${event.emojis.length} emoji(s)',
    );
  });

  bot.onGuildStickersUpdate.listen((event) {
    logger.info(
      'Guild ${event.guildId} now has ${event.stickers.length} sticker(s)',
    );
  });

  bot.onWebhooksUpdate.listen((event) {
    logger.info('Webhooks changed in channel ${event.channelId}');
  });

  bot.onInviteCreate.listen((event) {
    logger.info(
      'Invite ${event.code} created for ${event.channelId} by '
      '${event.inviter?.username ?? 'unknown'}, expires ${event.expiresAt}',
    );
  });

  bot.onInviteDelete.listen((event) {
    logger.info('Invite ${event.code} deleted');
  });

  bot.onGuildAuditLogEntryCreate.listen((event) {
    logger.info(
      'Audit log entry ${event.entry.actionType} in ${event.guildId} by '
      '${event.entry.userId}',
    );
  });
}
