import 'package:fluxer_dart/fluxer_dart.dart';

import 'await_reply.dart';
import 'guild_context.dart';

/// `!forgetme` — deletes every message this bot has ever sent in the
/// guild, in every channel. Guild owner only, after a typed confirmation.
///
/// `UserRestManager.deleteAllOwnMessagesInGuild` asks a user for sudo
/// verification but not a bot, so the request alone is enough and it
/// cannot be undone. This command adds the confirmation the API does
/// not.
Future<void> handleForgetMe(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final guild = await context.bot.guild(guildId);
  if (guild.ownerId != context.message.author.id) {
    await context.reply(
      MessageBuilder(content: 'Only the guild owner can do this.'),
    );
    return;
  }

  await context.reply(
    MessageBuilder(
      content:
          'This deletes **every** message I have sent in this guild, in '
          'every channel, and cannot be undone. Type `delete everything` '
          'within 30 seconds to confirm.',
    ),
  );
  final answer = await awaitReply(
    context.bot,
    channelId: context.message.channelId,
    userId: context.message.author.id,
    timeout: const Duration(seconds: 30),
  );
  if (answer?.trim() != 'delete everything') {
    await context.reply(MessageBuilder(content: 'Cancelled.'));
    return;
  }

  await context.bot.users.deleteAllOwnMessagesInGuild(guildId);
}
