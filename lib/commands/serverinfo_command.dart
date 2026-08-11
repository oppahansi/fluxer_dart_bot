import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!serverinfo` — basic guild stats plus vanity URL, if the guild has
/// one. No permission gate: this is the same information any member can
/// already see in the client, not a moderation action.
///
/// Deliberately calls `bot.guilds.get()` (always a fresh REST fetch)
/// rather than `bot.guild()` (GUILD_CREATE-cached): confirmed live that
/// the GUILD_CREATE gateway payload's `properties` object doesn't carry
/// `online_count` at all, so the cached copy always reports it as
/// unknown — a stats command showing stale/incomplete numbers defeats
/// its own purpose.
Future<void> handleServerInfo(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final guild = await context.bot.guilds.get(guildId);
  final vanity = guild.vanityUrlCode == null
      ? 'none'
      : 'fluxer.app/i/${guild.vanityUrlCode}';

  await context.reply(
    MessageBuilder(
      content:
          '**${guild.name}**\n'
          'Members: ${guild.memberCount ?? 'unknown'} '
          '(${guild.onlineCount ?? 'unknown'} online)\n'
          'Owner: <@${guild.ownerId}>\n'
          'Vanity invite: $vanity',
    ),
  );
}
