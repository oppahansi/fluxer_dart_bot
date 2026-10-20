import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!counts` — member and online counts for the guild and this channel,
/// from the gateway's count requests.
///
/// These are cheaper than paging members over REST, and the online count
/// exists nowhere else. A guild's online count covers the members who
/// share a channel with this bot (the whole guild for a bot holding
/// `administrator`); a channel's covers those who can view it.
Future<void> handleCounts(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final [guild] = await context.bot.guildCounts([guildId]);
  final channels = await context.bot.channelMemberCounts(guildId, [
    context.message.channelId,
  ]);
  final channel = channels.firstOrNull;
  await context.reply(
    MessageBuilder(
      content:
          'Guild: ${guild.onlineCount} online of ${guild.memberCount}.\n'
          '${channel == null ? 'This channel: not countable (needs viewChannelMembers).' : 'This channel: ${channel.onlineCount} online of ${channel.memberCount} who can see it.'}',
    ),
  );
}
