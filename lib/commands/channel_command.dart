import 'package:fluxer_dart/fluxer_dart.dart';

/// `!channel create <name>` / `!channel rename <name>` / `!channel delete`
/// — guild channel administration. A single command with an action
/// sub-argument rather than a subcommand tree: `CommandRouter` has no
/// concept of nested commands, and building one just for three actions
/// would be exactly the speculative framework surface this roadmap's own
/// design principles rule out. `rename`/`delete` act on the channel the
/// command was typed in.
Future<void> handleChannel(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!channel create|rename|delete ...`'),
    );
    return;
  }

  final action = context.args.first;
  final rest = context.args.skip(1).join(' ');
  final channelId = context.message.channelId;

  switch (action) {
    case 'create':
      if (rest.isEmpty) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!channel create <name>`'),
        );
        return;
      }
      final channel = await context.bot.channel(channelId);
      final guildId = channel.guildId;
      if (guildId == null) {
        await context.reply(
          MessageBuilder(
            content:
                'This channel has no guild to create a sibling channel in.',
          ),
        );
        return;
      }
      final created = await context.bot.guilds.createChannel(
        guildId,
        ChannelCreateBuilder(name: rest, type: ChannelType.guildText),
      );
      await context.reply(
        MessageBuilder(content: 'Created "${created.name}" (${created.id}).'),
      );

    case 'rename':
      if (rest.isEmpty) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!channel rename <name>`'),
        );
        return;
      }
      final current = await context.bot.channel(channelId);
      final currentType = current.type;
      if (currentType == null) {
        await context.reply(
          MessageBuilder(
            content:
                "This channel's type isn't recognized, so it can't be safely updated.",
          ),
        );
        return;
      }
      await context.bot.channels.update(
        channelId,
        ChannelUpdateBuilder(currentType).name(rest),
      );

    case 'delete':
      await context.bot.channels.delete(channelId);

    default:
      await context.reply(
        MessageBuilder(
          content: 'Unknown action `$action`. Use create, rename, or delete.',
        ),
      );
  }
}
