import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';
import 'setup_flow.dart';

/// `!setup` — must be run from inside the guild being configured (not a
/// DM: there'd be no way to tell which guild you meant, and
/// `requireGuildContext` already rejects DMs with an explanation for
/// free), and only by that guild's owner. The bot then continues the
/// rest of the conversation entirely over DM — see `setup_flow.dart`'s
/// doc comment for why DM rather than an ephemeral reply.
Future<void> handleSetup(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final guild = await context.bot.guilds.get(guildId);
  if (context.message.author.id != guild.ownerId) {
    await context.reply(
      MessageBuilder(content: "Only this server's owner can run `!setup`."),
    );
    return;
  }

  final dmChannel = await context.bot.users.createDm(guild.ownerId);
  await context.reply(
    MessageBuilder(content: "Check your DMs — let's get ${guild.name} set up."),
  );
  await runSetupFlow(context.bot, guild, dmChannel.id, guild.ownerId);
}
