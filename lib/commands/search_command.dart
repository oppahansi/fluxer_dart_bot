import 'package:fluxer_dart/fluxer_dart.dart';

import 'api_error.dart';
import 'guild_context.dart';

/// `!search <text>` — full-text search over the guild's messages with
/// [MessageSearchBuilder].
///
/// Search runs against an index filled shortly after a message is sent,
/// so a brand-new message can be missing for a moment, and a guild whose
/// index is still being built answers with no results and
/// [MessageSearchResults.indexing] set.
Future<void> handleSearch(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final text = context.args.join(' ');
  if (text.isEmpty) {
    await context.reply(MessageBuilder(content: 'Usage: `!search <text>`'));
    return;
  }

  try {
    final results = await context.bot.messages.search(
      MessageSearchBuilder()
          .inGuild(guildId)
          .content(text)
          .page(1, hitsPerPage: 5),
    );
    if (results.indexing) {
      await context.reply(
        MessageBuilder(
          content: 'The search index is still being built. Try again shortly.',
        ),
      );
      return;
    }
    if (results.messages.isEmpty) {
      await context.reply(
        MessageBuilder(content: 'No messages match "$text".'),
      );
      return;
    }
    final lines = results.messages.map(
      (m) =>
          '- ${m.author.username} in <#${m.channelId}>: '
          '${m.content.length > 80 ? '${m.content.substring(0, 80)}…' : m.content}',
    );
    await context.reply(
      MessageBuilder(
        content:
            '${results.total} match(es), newest first:\n${lines.join('\n')}',
      ).allowedMentions(AllowedMentions.none),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Search failed: ${describeApiError(error)}'),
    );
  }
}
