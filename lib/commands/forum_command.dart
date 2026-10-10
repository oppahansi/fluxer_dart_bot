import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

const _usage =
    'Usage: `!forum create <name>`, `!forum tag <forum id> <name>`, '
    '`!forum post <forum id> <title> | <body>`';

/// `!forum create|tag|post` — forum channels.
///
/// A forum channel holds no messages of its own. Everything in it is a
/// post, and a post is a public thread whose first message is created
/// with it, so `post` goes through `ThreadRestManager.createPost` rather
/// than `MessageRestManager.send`.
///
/// `tag` and `post` take the forum's id because a command cannot be sent
/// in the forum channel itself, only inside one of its posts.
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
          ChannelCreateBuilder(
            name: rest.join('-'),
            type: ChannelType.guildForum,
          ),
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

      default:
        await context.reply(MessageBuilder(content: _usage));
    }
  } on FluxerApiException catch (e) {
    await context.reply(
      MessageBuilder(content: 'That failed: ${e.message} (`${e.errorCode}`)'),
    );
  }
}
