import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!emoji add <name> <image_data_uri>` / `!emoji clone <source_emoji_id>`
/// / `!emoji delete <emoji_id>` — requires `createExpressions`. Confirmed
/// live against Fluxer: all three emoji routes (create, clone, delete)
/// check `createExpressions`, not `manageExpressions` — the latter isn't
/// consulted by any of them despite the name suggesting otherwise.
Future<void> handleEmoji(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!emoji add|clone|delete ...`'),
    );
    return;
  }

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final action = context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (action) {
      case 'add':
        if (rest.length < 2) {
          await context.reply(
            MessageBuilder(
              content: 'Usage: `!emoji add <name> <image_data_uri>`',
            ),
          );
          return;
        }
        final emoji = await context.bot.emojis.create(
          guildId,
          name: rest[0],
          image: rest[1],
        );
        await context.reply(
          MessageBuilder(
            content: 'Created emoji "${emoji.name}" (${emoji.id}).',
          ),
        );

      case 'clone':
        final sourceId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (sourceId == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!emoji clone <source_emoji_id>`'),
          );
          return;
        }
        final emoji = await context.bot.emojis.clone(
          guildId,
          Snowflake(sourceId),
        );
        await context.reply(
          MessageBuilder(
            content: 'Cloned emoji "${emoji.name}" (${emoji.id}).',
          ),
        );

      case 'delete':
        final emojiId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (emojiId == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!emoji delete <emoji_id>`'),
          );
          return;
        }
        await context.bot.emojis.delete(guildId, Snowflake(emojiId));
        await context.reply(MessageBuilder(content: 'Deleted emoji $emojiId.'));

      default:
        await context.reply(
          MessageBuilder(
            content: 'Unknown action `$action`. Use add, clone, or delete.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update emojis: ${error.message}'),
    );
  }
}
