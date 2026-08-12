import 'package:fluxer_dart/fluxer_dart.dart';

/// Resolves the guild the triggering message's channel belongs to,
/// replying with an explanation and returning `null` if it's not a
/// guild channel at all (a DM). Shared by every moderation/admin command
/// here since each one needs exactly this before it can do anything.
Future<Snowflake?> requireGuildContext(CommandContext context) async {
  final channel = await context.bot.channel(context.message.channelId);
  final guildId = channel.guildId;
  if (guildId == null) {
    await context.reply(
      MessageBuilder(content: 'This command only works in a guild channel.'),
    );
  }
  return guildId;
}
