import 'package:fluxer_dart/fluxer_dart.dart';

/// Replies to the triggering message with an actual `message_reference`,
/// via `MessageBuilder.replyTo()` — distinct from `context.reply()`
/// (`Bot.reply()`), which only sends to the same channel and doesn't set
/// a reference at all.
Future<void> handleReply(CommandContext context) async {
  await context.bot.messages.send(
    context.message.channelId,
    MessageBuilder(
      content: 'This is a real reply, not just a same-channel message.',
    ).replyTo(context.message.id),
  );
}
