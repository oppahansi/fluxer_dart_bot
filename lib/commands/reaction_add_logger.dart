import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs every reaction added anywhere the bot can see, demonstrating
/// `onMessageReactionAdd` — the follow-up dispatch to pair with the
/// `!react` command's own reaction add.
void handleMessageReactionAdd(MessageReactionAddEvent event, Logger logger) {
  logger.info(
    '[reaction] ${event.emoji} on message ${event.messageId} by user ${event.userId}',
  );
}

/// Logs a batch of DM reactions delivered as one
/// `MESSAGE_REACTION_ADD_MANY`. Only a bot that identifies with
/// `SessionFlag.debounceMessageReactions` receives these; this example
/// does not set it, so with the default setup this never fires.
void handleMessageReactionAddMany(
  MessageReactionAddManyEvent event,
  Logger logger,
) {
  logger.info(
    '[reaction] ${event.reactions.length} reactions on message '
    '${event.messageId}: '
    '${event.reactions.map((r) => '${r.emoji} by ${r.userId}').join(', ')}',
  );
}
