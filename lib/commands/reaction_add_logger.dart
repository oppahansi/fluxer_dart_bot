import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs every reaction added anywhere the bot can see, demonstrating
/// `onMessageReactionAdd` — the follow-up dispatch to pair with the
/// `!react` command's own reaction add.
void handleMessageReactionAdd(MessageReactionAddEvent event, Logger logger) {
  logger.info(
    '[reaction] ${event.emoji} on message ${event.messageId} by user ${event.userId}',
  );
}
