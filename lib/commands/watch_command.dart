import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!watch <user_id>` — subscribes to a member's presence and reports
/// it.
///
/// A bot receives no presences unless it asks: a Lazy Request with
/// [GuildSubscription.members] starts `PRESENCE_UPDATE` for those
/// members, which `Bot` caches and the presence logger prints. The
/// subscription replaces the previous member list for the guild, so this
/// watches one member at a time. The current presence comes from a
/// member query with presences, since a subscription only reports
/// changes.
Future<void> handleWatch(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final userId = context.args.isEmpty ? null : int.tryParse(context.args.first);
  if (userId == null) {
    await context.reply(MessageBuilder(content: 'Usage: `!watch <user_id>`'));
    return;
  }
  final id = Snowflake(userId);

  context.bot.subscribe(guildId, GuildSubscription(members: [id]));
  final (:members, :presences) = await context.bot.queryMembers(
    guildId,
    userIds: [id],
    presences: true,
  );
  if (members.isEmpty) {
    await context.reply(MessageBuilder(content: 'No member $userId here.'));
    return;
  }
  final status = presences.isEmpty ? 'offline' : presences.single.status.value;
  final custom = presences.firstOrNull?.customStatus?.text;
  await context.reply(
    MessageBuilder(
      content:
          'Watching ${members.single.displayName}: $status'
          '${custom != null ? ' — "$custom"' : ''}. Changes go to the log.',
    ),
  );
}
