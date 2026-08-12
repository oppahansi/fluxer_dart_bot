import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!sticker add`, `!sticker clone`, and `!sticker delete` (a name plus
/// image data URI for `add`, a single id for the other two) — requires
/// `createExpressions`, same as `!emoji` (verified live: stickers use
/// the same permission split as emojis).
Future<void> handleSticker(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!sticker add|clone|delete ...`'),
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
              content: 'Usage: `!sticker add <name> <image_data_uri>`',
            ),
          );
          return;
        }
        final sticker = await context.bot.stickers.create(
          guildId,
          name: rest[0],
          image: rest[1],
        );
        await context.reply(
          MessageBuilder(
            content: 'Created sticker "${sticker.name}" (${sticker.id}).',
          ),
        );

      case 'clone':
        final sourceId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (sourceId == null) {
          await context.reply(
            MessageBuilder(
              content: 'Usage: `!sticker clone <source_sticker_id>`',
            ),
          );
          return;
        }
        final sticker = await context.bot.stickers.clone(
          guildId,
          Snowflake(sourceId),
        );
        await context.reply(
          MessageBuilder(
            content: 'Cloned sticker "${sticker.name}" (${sticker.id}).',
          ),
        );

      case 'delete':
        final stickerId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (stickerId == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!sticker delete <sticker_id>`'),
          );
          return;
        }
        await context.bot.stickers.delete(guildId, Snowflake(stickerId));
        await context.reply(
          MessageBuilder(content: 'Deleted sticker $stickerId.'),
        );

      default:
        await context.reply(
          MessageBuilder(
            content: 'Unknown action `$action`. Use add, clone, or delete.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update stickers: ${error.message}'),
    );
  }
}
