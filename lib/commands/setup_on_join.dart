import 'package:fluxer_dart/fluxer_dart.dart';

import 'setup_flow.dart';

/// Fires the same flow `!setup` triggers, but unprompted the moment the
/// bot is actually added to a guild — the other common pre-interactions
/// Discord-bot pattern (DM the owner on join, instead of waiting for a
/// command).
///
/// Filtered to `GUILD_MEMBER_ADD` where the joining member is the bot
/// itself, deliberately *not* `GUILD_CREATE`: `GUILD_CREATE` fires for
/// every guild the bot's in on every reconnect, not just fresh invites
/// (confirmed live — see `local-instance.md`), so wiring this to it
/// would re-open a "let's get set up!" DM on every bot restart.
///
/// Caveat: whether `GUILD_MEMBER_ADD` actually fires for the bot's own
/// join — as opposed to only being delivered for guilds it's already
/// in, for other members joining — wasn't verified against a real
/// invite in this session. Verifying it would have meant resetting this
/// test setup's OAuth2 client secret to redo the invite flow, a real
/// credential rotation that's out of scope for a live check. Confirm
/// this against an actual invite before relying on it in production;
/// the explicit `!setup` command needs no such signal and works
/// regardless.
Future<void> handleGuildMemberAddSetupPrompt(
  GuildMemberAddEvent event,
  Bot bot,
) async {
  if (event.member.user.id != bot.selfId) return;

  final guild = await bot.guilds.get(event.guildId);
  final dmChannel = await bot.users.createDm(guild.ownerId);
  await runSetupFlow(bot, guild, dmChannel.id, guild.ownerId);
}
