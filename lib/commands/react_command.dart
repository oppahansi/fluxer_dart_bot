import 'package:fluxer_dart/fluxer_dart.dart';

/// Adds a 👍 reaction to the triggering message. Pair with
/// `bot.onMessageReactionAdd` (wired in `bin/bot.dart`) to see the
/// follow-up dispatch when someone reacts back.
Future<void> handleReact(CommandContext context) async {
  await context.bot.messages.addReaction(
    context.message.channelId,
    context.message.id,
    '👍',
  );
}
