import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!ban <user_id> [reason...]` — requires `banMembers`.
Future<void> handleBan(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!ban <user_id> [reason]`'),
    );
    return;
  }
  final userId = int.tryParse(context.args.first);
  if (userId == null) {
    await context.reply(MessageBuilder(content: 'Could not parse a user id.'));
    return;
  }
  final reason = context.args.length > 1
      ? context.args.skip(1).join(' ')
      : null;

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  try {
    await context.bot.bans.ban(guildId, Snowflake(userId), reason: reason);
    await context.reply(MessageBuilder(content: 'Banned user $userId.'));
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not ban: ${error.message}'),
    );
  }
}

/// `!unban <user_id>` — requires `banMembers`.
Future<void> handleUnban(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(MessageBuilder(content: 'Usage: `!unban <user_id>`'));
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
    await context.bot.bans.unban(guildId, Snowflake(userId));
    await context.reply(MessageBuilder(content: 'Unbanned user $userId.'));
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not unban: ${error.message}'),
    );
  }
}
