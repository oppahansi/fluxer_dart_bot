import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!timeout <user_id> <minutes> [reason...]` — requires
/// `moderateMembers`. `!timeout <user_id> 0` clears an existing timeout.
Future<void> handleTimeout(CommandContext context) async {
  if (context.args.length < 2) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!timeout <user_id> <minutes> [reason]`'),
    );
    return;
  }
  final userId = int.tryParse(context.args[0]);
  final minutes = int.tryParse(context.args[1]);
  if (userId == null || minutes == null || minutes < 0) {
    await context.reply(
      MessageBuilder(content: 'Could not parse a user id and a minute count.'),
    );
    return;
  }
  final reason = context.args.length > 2
      ? context.args.skip(2).join(' ')
      : null;

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final until = minutes == 0
      ? null
      : DateTime.now().toUtc().add(Duration(minutes: minutes));

  try {
    await context.bot.members.timeout(
      guildId,
      Snowflake(userId),
      until: until,
      reason: reason,
    );
    await context.reply(
      MessageBuilder(
        content: minutes == 0
            ? 'Cleared timeout for user $userId.'
            : 'Timed out user $userId for $minutes minute(s).',
      ),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update timeout: ${error.message}'),
    );
  }
}
