import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

const _usage =
    'Usage: `!forum create <name>`, `!forum tag <forum id> <name>`, '
    '`!forum post <forum id> <title> | <body>`, '
    '`!forum search <forum id> <title words>`, `!forum posts <forum id>`';

/// `!forum create|tag|post|search|posts` — forum channels.
///
/// A forum channel holds no messages of its own. Everything in it is a
/// post, and a post is a public thread whose first message is created
/// with it, so `post` goes through `ThreadRestManager.createPost` rather
/// than `MessageRestManager.send`.
///
/// `tag` and `post` take the forum's id because a command cannot be sent
/// in the forum channel itself, only inside one of its posts.
///
/// `search` finds posts by title through the thread search index, which
/// can answer "not ready yet" instead of results. `posts` lists the
/// active posts with who started each and how it opens, using one
/// `postData` call for all of them rather than a fetch per post.
Future<void> handleForum(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final subcommand = context.args.isEmpty ? '' : context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (subcommand) {
      case 'create' when rest.isNotEmpty:
        final forum = await context.bot.guilds.createChannel(
          guildId,
          // A forum's defaults shape every post made in it: newest
          // activity first, a list layout, and a thumbs-up offered on each.
          ChannelCreateBuilder(
                name: rest.join('-'),
                type: ChannelType.guildForum,
              )
              .defaultSortOrder(ForumSortOrder.latestActivity)
              .defaultLayout(ForumLayout.list)
              .defaultReaction(const ForumDefaultReaction(emojiName: '👍'))
              .defaultAutoArchiveDuration(ThreadAutoArchiveDuration.oneWeek),
        );
        await context.reply(
          MessageBuilder(
            content: 'Created forum <#${forum.id}> (`${forum.id}`).',
          ),
        );

      case 'tag' when rest.length >= 2:
        final forum = await context.bot.channels.createTag(
          Snowflake.parse(rest.first),
          name: rest.skip(1).join(' '),
          auditLogReason: 'Requested by ${context.message.author.username}',
        );
        await context.reply(
          MessageBuilder(
            content:
                'Tags on <#${forum.id}>: '
                '${forum.availableTags.map((t) => '`${t.name}`').join(', ')}',
          ),
        );

      case 'post' when rest.length >= 2:
        final forumId = Snowflake.parse(rest.first);
        final (title, body) = switch (rest.skip(1).join(' ').split('|')) {
          [final title, ...final body] when body.isNotEmpty => (
            title.trim(),
            body.join('|').trim(),
          ),
          [final title, ...] => (title.trim(), title.trim()),
          [] => ('', ''),
        };
        if (title.isEmpty || body.isEmpty) {
          await context.reply(MessageBuilder(content: _usage));
          return;
        }
        final post = await context.bot.threads.createPost(
          forumId,
          name: title,
          message: MessageBuilder(
            content: body,
          ).allowedMentions(AllowedMentions.none),
        );
        await context.reply(
          MessageBuilder(content: 'Posted <#${post.thread.id}>.'),
        );

      case 'search' when rest.length >= 2:
        final results = await context.bot.threads.search(
          Snowflake.parse(rest.first),
          name: rest.skip(1).join(' '),
          limit: 10,
        );
        if (results.retryAfter case final wait?) {
          await context.reply(
            MessageBuilder(
              content:
                  'The thread search index is not ready; try again in '
                  '${wait.inSeconds + 1} s.',
            ),
          );
          return;
        }
        await context.reply(
          MessageBuilder(
            content: results.threads.isEmpty
                ? 'No posts match.'
                : '${results.totalResults} post(s):\n'
                      '${results.threads.map((t) => '- <#${t.id}> ${t.name}').join('\n')}',
          ),
        );

      case 'posts' when rest.isNotEmpty:
        final forumId = Snowflake.parse(rest.first);
        final active = await context.bot.threads.listActive(guildId);
        final posts = active.threads
            .where((t) => t.parentId == forumId)
            .take(100)
            .toList();
        if (posts.isEmpty) {
          await context.reply(MessageBuilder(content: 'No active posts.'));
          return;
        }
        final data = await context.bot.threads.postData(forumId, [
          for (final p in posts) p.id,
        ]);
        String opening(Snowflake id) {
          final text = data[id]?.firstMessage?.content ?? '(deleted)';
          return text.length > 60 ? '${text.substring(0, 60)}…' : text;
        }

        await context.reply(
          MessageBuilder(
            content: posts
                .map(
                  (p) =>
                      '- **${p.name}** by '
                      '${data[p.id]?.owner?.displayName ?? 'someone who left'}: '
                      '${opening(p.id)}',
                )
                .join('\n'),
          ).allowedMentions(AllowedMentions.none),
        );

      default:
        await context.reply(MessageBuilder(content: _usage));
    }
  } on FluxerApiException catch (e) {
    await context.reply(
      MessageBuilder(content: 'That failed: ${e.message} (`${e.errorCode}`)'),
    );
  }
}
