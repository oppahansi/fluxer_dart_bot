import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!nick <name>` / `!nick reset` — changes this bot's own nickname in
/// the current guild through `PATCH /guilds/{id}/members/@me`.
///
/// The `@me` member routes are the only way a bot edits itself: it holds
/// no user session, so the account-wide profile is out of reach, but its
/// per-guild profile is not. [CurrentMemberUpdateBuilder.nick] with
/// `null` sends an explicit `null`, which is what removes a nickname.
Future<void> handleNick(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  if (context.args.isEmpty) {
    final me = await context.bot.members.getCurrent(guildId);
    await context.reply(
      MessageBuilder(
        content: me.nick == null
            ? 'No nickname here. Usage: `!nick <name>` or `!nick reset`'
            : 'Current nickname: ${me.nick}',
      ),
    );
    return;
  }

  final nick = context.args.join(' ');
  try {
    final me = await context.bot.members.updateCurrent(
      guildId,
      CurrentMemberUpdateBuilder().nick(nick == 'reset' ? null : nick),
      auditLogReason: 'Requested by ${context.message.author.username}',
    );
    await context.reply(
      MessageBuilder(
        content: me.nick == null
            ? 'Nickname removed.'
            : 'Nickname set to ${me.nick}.',
      ),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not change nickname: ${error.message}'),
    );
  }
}
