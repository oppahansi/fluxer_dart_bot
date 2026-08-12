import 'package:fluxer_dart/fluxer_dart.dart';

import 'await_reply.dart';

MessageBuilder _timedOutReply() => MessageBuilder(
  content:
      'Setup timed out — run `!setup` again from the server whenever '
      "you're ready.",
);

/// The actual setup conversation, run entirely over a DM channel already
/// opened with the guild's owner. Two questions, then a summary — enough
/// to demonstrate a real multi-turn flow without pretending this example
/// bot has anywhere to persist the answers.
///
/// This is the closest equivalent this platform has to Discord's
/// ephemeral-only-you setup wizards: Fluxer has no ephemeral messages or
/// interactions at all (see the bot README's "Where this is limited"
/// section), so "only the owner sees this" here means "sent over DM,"
/// not a visibility flag on a channel message.
Future<void> runSetupFlow(
  Bot bot,
  Guild guild,
  Snowflake dmChannelId,
  Snowflake ownerId,
) async {
  await bot.messages.send(
    dmChannelId,
    MessageBuilder(
      content:
          "Hi! I'm set up in **${guild.name}**. Two quick questions — "
          "reply here, I'll wait up to 2 minutes for each.\n\n"
          '**1/2** — Which channel name should I treat as the '
          'announcements channel? (type a name, or "skip")',
    ),
  );
  final announcementsChannel = await awaitReply(
    bot,
    channelId: dmChannelId,
    userId: ownerId,
  );
  if (announcementsChannel == null) {
    await bot.messages.send(dmChannelId, _timedOutReply());
    return;
  }

  await bot.messages.send(
    dmChannelId,
    MessageBuilder(
      content:
          '**2/2** — Should `!purge` require the `manageMessages` '
          'permission, or should only you be able to run it? Type '
          '"strict" or "lenient".',
    ),
  );
  final purgePolicy = await awaitReply(
    bot,
    channelId: dmChannelId,
    userId: ownerId,
  );
  if (purgePolicy == null) {
    await bot.messages.send(dmChannelId, _timedOutReply());
    return;
  }

  await bot.messages.send(
    dmChannelId,
    MessageBuilder(
      content:
          'All set for **${guild.name}**:\n'
          '- Announcements channel: `$announcementsChannel`\n'
          '- Purge policy: `$purgePolicy`\n\n'
          "This example doesn't persist those anywhere — there's no "
          'database in this reference implementation. A real bot would '
          'save them and read them back wherever they matter (e.g. '
          '`!purge`'
          "'s own permission gate) instead of just echoing them here.",
    ),
  );
}
