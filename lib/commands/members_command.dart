import 'dart:math';

import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';
import 'paginator.dart';

const _pageSize = 10;

/// `!members` — paginated member list via [sendPaginated]. Fetches up
/// to Fluxer's own per-call max (1000, `GuildMemberRestManager.list`'s
/// `limit`) in one request rather than following `after` cursors for
/// guilds bigger than that — out of scope for a demo bot, noted rather
/// than silently capped without explanation.
Future<void> handleMembers(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final members = await context.bot.members.list(guildId, limit: 1000);
  if (members.isEmpty) {
    await context.reply(MessageBuilder(content: 'No members found.'));
    return;
  }

  final totalPages = (members.length / _pageSize).ceil();

  String renderPage(int page) {
    final start = page * _pageSize;
    final end = min(start + _pageSize, members.length);
    final lines = members
        .sublist(start, end)
        .map((m) => '- ${m.user.username} (${m.user.id})')
        .join('\n');
    return 'Members (page ${page + 1}/$totalPages, ${members.length} total):\n$lines';
  }

  await sendPaginated(context, totalPages: totalPages, render: renderPage);
}
