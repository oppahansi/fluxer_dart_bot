import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!kick <user_id> [reason...]` — requires `kickMembers`.
Future<void> handleKick(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!kick <user_id> [reason]`'),
    );
    return;
  }
  final userId = int.tryParse(context.args.first);
  if (userId == null) {
    await context.reply(MessageBuilder(content: 'Could not parse a user id.'));
    return;
  }

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  try {
    await context.bot.members.kick(guildId, Snowflake(userId));
    await context.reply(MessageBuilder(content: 'Kicked user $userId.'));
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not kick: ${error.message}'),
    );
  }
}
