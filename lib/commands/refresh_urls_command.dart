import 'package:fluxer_dart/fluxer_dart.dart';

/// `!refreshurls` — re-signs the attachment URLs on the replied-to
/// message.
///
/// An attachment URL carries a signature that expires, so a URL stored
/// from an earlier message eventually stops working. This is the route
/// that makes a stored URL fetchable again without re-reading the
/// message, which matters for anything that keeps attachment links of its
/// own rather than re-fetching from the API each time.
Future<void> handleRefreshUrls(CommandContext context) async {
  final target = context.message.messageReference?.messageId;
  if (target == null) {
    await context.reply(
      MessageBuilder(
        content: 'Reply to a message with attachments, with `!refreshurls`.',
      ),
    );
    return;
  }

  final message = await context.bot.messages.fetch(
    context.message.channelId,
    target,
  );
  final urls = message.attachments
      .map((a) => a.url)
      .whereType<String>()
      .toList(growable: false);

  if (urls.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'That message has no attachments.'),
    );
    return;
  }

  final refreshed = await context.bot.attachments.refreshUrls(urls);
  final changed = refreshed.where((r) => r.wasRefreshed).length;

  await context.reply(
    MessageBuilder(
      content:
          'Refreshed ${refreshed.length} attachment URL(s); $changed came '
          'back with a new signature.',
    ),
  );
}
