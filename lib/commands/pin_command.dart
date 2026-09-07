import 'package:fluxer_dart/fluxer_dart.dart';

/// `!pin` — pins the message this command replies to, or the command
/// message itself when it is not a reply.
///
/// Pinning needs `pinMessages`, which is a separate permission from
/// `manageMessages`.
Future<void> handlePin(CommandContext context) async {
  final target =
      context.message.messageReference?.messageId ?? context.message.id;

  await context.bot.messages.pin(
    context.message.channelId,
    target,
    auditLogReason: 'Pinned by ${context.message.author.username}',
  );
  await context.reply(MessageBuilder(content: 'Pinned message $target.'));
}

/// `!unpin` — the inverse of [handlePin].
Future<void> handleUnpin(CommandContext context) async {
  final target =
      context.message.messageReference?.messageId ?? context.message.id;

  await context.bot.messages.unpin(
    context.message.channelId,
    target,
    auditLogReason: 'Unpinned by ${context.message.author.username}',
  );
  await context.reply(MessageBuilder(content: 'Unpinned message $target.'));
}

/// `!pins` — lists the channel's pinned messages.
///
/// The route answers with a page envelope rather than a bare array, so
/// `hasMore` has to be reported rather than assuming one call returns
/// everything.
Future<void> handlePins(CommandContext context) async {
  final page = await context.bot.messages.pins(context.message.channelId);

  if (page.isEmpty) {
    await context.reply(MessageBuilder(content: 'No pinned messages here.'));
    return;
  }

  final lines = page.items
      .map((pin) {
        final preview = pin.message.content;
        final trimmed = preview.length > 60
            ? '${preview.substring(0, 60)}...'
            : preview;
        return '- `${pin.message.id}` by ${pin.message.author.username}: $trimmed';
      })
      .join('\n');

  final more = page.hasMore ? '\n(more pins not shown)' : '';
  await context.reply(
    MessageBuilder(content: '${page.length} pinned message(s):\n$lines$more'),
  );
}
