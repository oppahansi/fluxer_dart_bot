import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!announce create|stats` — announcement channel management.
///
/// An announcement channel is an ordinary guild text channel whose
/// messages can be published to channels in other guilds that follow it.
/// Creating one is just creating a channel of type
/// [ChannelType.guildAnnouncement].
///
/// The other two halves of the flow are separate commands because they
/// need different permissions: [handleFollow] needs `manageWebhooks` in
/// the channel being subscribed, and [handlePublish] needs only
/// `sendMessages`, which every member has.
Future<void> handleAnnounce(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final subcommand = context.args.isEmpty ? '' : context.args.first;
  final rest = context.args.skip(1).toList();

  switch (subcommand) {
    case 'create':
      if (rest.isEmpty) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!announce create <name>`'),
        );
        return;
      }
      final channel = await context.bot.guilds.createChannel(
        guildId,
        ChannelCreateBuilder(
          name: rest.join('-'),
          type: ChannelType.guildAnnouncement,
        ),
      );
      await context.reply(
        MessageBuilder(
          content:
              'Created announcement channel <#${channel.id}> (`${channel.id}`). '
              'Other guilds can follow it, and messages in it can be '
              'published with `!announce publish`.',
        ),
      );

    case 'stats':
      final stats = await context.bot.channels.followerStats(
        context.message.channelId,
      );
      await context.reply(
        MessageBuilder(
          content:
              '${stats.channelCount} channel(s) across ${stats.guildCount} '
              'guild(s) follow this channel.',
        ),
      );

    default:
      await context.reply(
        MessageBuilder(content: 'Usage: `!announce create|stats`'),
      );
  }
}

/// `!follow <announcement channel id>` — subscribes this channel to an
/// announcement channel.
///
/// Following creates a channel follower webhook in this channel, and that
/// webhook is what delivers the copies, so deleting it stops following.
/// Needs `viewChannel` on the announcement channel and `manageWebhooks`
/// here.
Future<void> handleFollow(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!follow <announcement channel id>`'),
    );
    return;
  }

  final followed = await context.bot.channels.follow(
    Snowflake.parse(context.args.first),
    targetChannelId: context.message.channelId,
    auditLogReason: 'Followed by ${context.message.author.username}',
  );
  await context.reply(
    MessageBuilder(
      content:
          'Now following `${followed.channelId}`. Copies arrive through '
          'webhook `${followed.webhookId}` — delete that webhook to stop.',
    ),
  );
}

/// `!publish` — crossposts the replied-to message to every channel
/// following this announcement channel.
///
/// Only a default message that is not a reply, a forward, or itself a
/// copy can be published. The API enforces `manageMessages` when
/// publishing someone else's message, so this command needs no
/// permission middleware of its own.
Future<void> handlePublish(CommandContext context) async {
  final target = context.message.messageReference?.messageId;
  if (target == null) {
    await context.reply(
      MessageBuilder(
        content: 'Reply to the message you want to publish, with `!publish`.',
      ),
    );
    return;
  }

  final published = await context.bot.messages.crosspost(
    context.message.channelId,
    target,
  );
  await context.reply(
    MessageBuilder(
      content: published.isCrossposted
          ? 'Published `$target` to every following channel.'
          : 'Published `$target`, but it came back without the crossposted '
                'flag set.',
    ),
  );
}

/// `!source` — where a crossposted copy came from.
///
/// Only meaningful on a message carrying [MessageFlag.isCrosspost], which
/// is a copy delivered by following an announcement channel rather than a
/// message sent in this channel directly.
Future<void> handleCrosspostSource(CommandContext context) async {
  final target = context.message.messageReference?.messageId;
  if (target == null) {
    await context.reply(
      MessageBuilder(content: 'Reply to a crossposted message with `!source`.'),
    );
    return;
  }

  final message = await context.bot.messages.fetch(
    context.message.channelId,
    target,
  );
  if (!message.isCrosspost) {
    await context.reply(
      MessageBuilder(
        content:
            'That message is not a crossposted copy, so it has no '
            'source guild.',
      ),
    );
    return;
  }

  final source = await context.bot.messages.crosspostSource(
    context.message.channelId,
    target,
  );
  final guild = source.guild;
  await context.reply(
    MessageBuilder().embed(
      EmbedBuilder()
          .title('Crossposted from ${guild.name}')
          .field('Guild ID', '${guild.id}')
          .field('Members', '${guild.approximateMemberCount ?? 'unknown'}')
          .field('Discoverable', guild.discoverable == true ? 'yes' : 'no')
          .build(),
    ),
  );
}
