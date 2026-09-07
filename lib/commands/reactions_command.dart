import 'package:fluxer_dart/fluxer_dart.dart';

/// `!reactors <emoji>` — lists who reacted to the replied-to message with
/// [emoji], following the cursor until every page is read.
///
/// The route pages with a cursor rather than returning everyone at once,
/// so a single call is not the whole answer.
Future<void> handleReactors(CommandContext context) async {
  final target = context.message.messageReference?.messageId;
  if (target == null || context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Reply to a message with `!reactors <emoji>`.'),
    );
    return;
  }

  final emoji = context.args.first;
  final names = <String>[];
  Snowflake? after;

  do {
    final page = await context.bot.messages.listReactionUsers(
      context.message.channelId,
      target,
      emoji,
      after: after,
    );
    names.addAll(page.items.map((u) => u.username));
    after = page.hasMore ? page.nextAfter : null;
  } while (after != null);

  await context.reply(
    MessageBuilder(
      content: names.isEmpty
          ? 'Nobody reacted with $emoji.'
          : '${names.length} reacted with $emoji: ${names.join(', ')}',
    ),
  );
}

/// `!clearreactions [emoji]` — clears every reaction from the replied-to
/// message, or only those using [emoji].
///
/// Both routes need `manageMessages`, unlike removing the bot's own
/// reaction.
Future<void> handleClearReactions(CommandContext context) async {
  final target = context.message.messageReference?.messageId;
  if (target == null) {
    await context.reply(
      MessageBuilder(
        content: 'Reply to a message with `!clearreactions [emoji]`.',
      ),
    );
    return;
  }

  final messages = context.bot.messages;
  if (context.args.isEmpty) {
    await messages.removeAllReactions(context.message.channelId, target);
    await context.reply(MessageBuilder(content: 'Cleared all reactions.'));
    return;
  }

  final emoji = context.args.first;
  await messages.removeEmojiReactions(context.message.channelId, target, emoji);
  await context.reply(MessageBuilder(content: 'Cleared $emoji reactions.'));
}
