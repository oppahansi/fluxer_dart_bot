import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!unreads <forum_channel_id>` — how many replies each active post in a
/// forum has, using Request Forum Unreads.
///
/// The command counts messages after an acknowledged one. A post's first
/// message has the post's own id, so acknowledging that id counts the
/// replies. The answer is capped at 25 per post.
Future<void> handleUnreads(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final forumId = context.args.isEmpty
      ? null
      : int.tryParse(context.args.first);
  if (forumId == null) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!unreads <forum_channel_id>`'),
    );
    return;
  }

  final active = await context.bot.threads.listActive(guildId);
  final posts = active.threads
      .where((t) => t.parentId == Snowflake(forumId))
      .take(40)
      .toList();
  if (posts.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'No active posts in that forum.'),
    );
    return;
  }

  final unreads = await context.bot.forumUnreads(guildId, Snowflake(forumId), [
    for (final post in posts)
      ForumUnreadRequest(post.id, ackMessageId: post.id),
  ]);
  final byId = {for (final u in unreads) u.threadId: u};
  await context.reply(
    MessageBuilder(
      content: posts
          .map((p) {
            final count = byId[p.id]?.count;
            return '- ${p.name}: ${count == null
                    ? '?'
                    : count >= 25
                    ? '25+'
                    : count} '
                'repl${count == 1 ? 'y' : 'ies'}';
          })
          .join('\n'),
    ),
  );
}
