import 'dart:async';

import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!memberlist` — subscribes to this channel's member list and prints
/// the first window the gateway sends, the way a client's sidebar sees
/// it: group headers in order, then their members with presence.
///
/// Run inside a thread it subscribes to the thread's member list
/// instead, which is a separate subscription (`thread_member_lists`).
/// Either keeps updating after this command returns, and `Bot` caches
/// every member and presence the updates carry.
Future<void> handleMemberList(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;
  final channelId = context.message.channelId;
  final channel = await context.bot.channel(channelId);

  try {
    if (channel is ThreadChannel) {
      final update = context.bot.onThreadMemberListUpdate
          .firstWhere((e) => e.threadId == channelId)
          .timeout(const Duration(seconds: 10));
      context.bot.subscribe(
        guildId,
        GuildSubscription(threadMemberLists: [channelId]),
      );
      final event = await update;
      await context.reply(
        MessageBuilder(
          content:
              'Thread members (${event.members.length}):\n'
              '${event.members.map((m) => '- ${m.member.member?.displayName ?? m.member.userId} — ${m.presence?.status.value ?? 'offline'}').join('\n')}',
        ),
      );
      return;
    }

    final update = context.bot.onGuildMemberListUpdate
        .firstWhere((e) => e.channelId == channelId)
        .timeout(const Duration(seconds: 10));
    context.bot.subscribe(
      guildId,
      GuildSubscription(
        memberListChannels: {
          channelId: [(0, 99)],
        },
      ),
    );
    final event = await update;
    final lines = <String>[];
    for (final op in event.ops.where((op) => op.isSync)) {
      for (final item in op.items) {
        lines.add(switch (item) {
          MemberListGroupItem(:final group) =>
            '**${group.isOnline
                ? 'Online'
                : group.isOffline
                ? 'Offline'
                : 'Role ${group.id}'}** — ${group.count}',
          MemberListMemberItem(:final member, :final presence) =>
            '- ${member.displayName} (${presence.status.value})',
        });
      }
    }
    await context.reply(
      MessageBuilder(
        content:
            'Member list: ${event.onlineCount} online of ${event.memberCount}\n'
            '${lines.join('\n')}',
      ),
    );
  } on TimeoutException {
    await context.reply(
      MessageBuilder(
        content:
            'No member list arrived. Viewing it needs viewChannelMembers in '
            'this channel.',
      ),
    );
  }
}
