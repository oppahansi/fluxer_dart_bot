import 'package:fluxer_dart/fluxer_dart.dart';

/// `!channel create <name>` / `!channel rename <name>` /
/// `!channel move <position>` / `!channel nest <category_id|none>` /
/// `!channel delete` — guild channel administration. A single command with an action
/// sub-argument rather than a subcommand tree: `CommandRouter` has no
/// concept of nested commands, and building one just for three actions
/// would be exactly the speculative framework surface this roadmap's own
/// design principles rule out. `rename`/`move`/`delete` act on the channel
/// the command was typed in.
///
/// `move` goes through the guild-wide reorder route even for one channel:
/// `PATCH /channels/{id}` has no position field. The reorder is answered
/// by `CHANNEL_UPDATE_BULK`, which the layout logger prints. `nest` moves
/// the channel into a category, or out of one with `none`, through
/// [ChannelUpdateBuilder.parent].
Future<void> handleChannel(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(
        content: 'Usage: `!channel create|rename|move|nest|delete ...`',
      ),
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

    case 'move':
      final position = int.tryParse(rest);
      if (position == null || position < 0) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!channel move <position>`'),
        );
        return;
      }
      final current = await context.bot.channel(channelId);
      final guildId = current.guildId;
      if (guildId == null) {
        await context.reply(
          MessageBuilder(content: 'Only a guild channel has a position.'),
        );
        return;
      }
      await context.bot.guilds.updateChannelPositions(guildId, [
        ChannelPositionUpdate(channelId, position: position),
      ]);
      final moved = await context.bot.channels.get(channelId);
      await context.reply(
        MessageBuilder(content: 'Moved to position ${moved.position}.'),
      );

    case 'nest':
      final categoryId = rest == 'none' ? null : int.tryParse(rest);
      if (rest != 'none' && categoryId == null) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!channel nest <category_id|none>`'),
        );
        return;
      }
      final current = await context.bot.channel(channelId);
      final currentType = current.type;
      if (currentType == null) return;
      final moved = await context.bot.channels.update(
        channelId,
        ChannelUpdateBuilder(
          currentType,
        ).parent(categoryId == null ? null : Snowflake(categoryId)),
      );
      await context.reply(
        MessageBuilder(
          content: moved.parentId == null
              ? 'Moved out of its category.'
              : 'Moved into category ${moved.parentId}.',
        ),
      );

    case 'delete':
      await context.bot.channels.delete(channelId);

    default:
      await context.reply(
        MessageBuilder(
          content:
              'Unknown action `$action`. Use create, rename, move, nest, or '
              'delete.',
        ),
      );
  }
}
