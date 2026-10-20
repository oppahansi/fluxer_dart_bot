import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!channels` — the guild's channel list laid out the way a client shows
/// it: top-level channels first, then each category with its children,
/// everything in `position` order.
///
/// One `GET /guilds/{id}/channels` returns every visible channel in full,
/// so there is no paging and no per-channel fetch. Threads are not part
/// of it; `!thread list` covers those.
Future<void> handleChannels(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final channels = await context.bot.guilds.listChannels(guildId);
  int byPosition(Channel a, Channel b) =>
      (a.position ?? 0).compareTo(b.position ?? 0);

  final categories = channels.whereType<GuildCategoryChannel>().toList()
    ..sort(byPosition);
  final children = channels.where((c) => c is! GuildCategoryChannel).toList()
    ..sort(byPosition);

  String line(Channel c) =>
      '- ${_icon(c)} ${c.name ?? '(unnamed)'} `${c.id}` (pos ${c.position})';

  final buffer = StringBuffer('Channels (${channels.length}):\n');
  for (final channel in children.where((c) => c.parentId == null)) {
    buffer.writeln(line(channel));
  }
  for (final category in categories) {
    buffer.writeln('**${category.name}** `${category.id}`');
    for (final channel in children.where((c) => c.parentId == category.id)) {
      buffer.writeln('  ${line(channel)}');
    }
  }
  await context.reply(MessageBuilder(content: buffer.toString().trimRight()));
}

String _icon(Channel channel) => switch (channel) {
  GuildTextChannel() => '#',
  GuildAnnouncementChannel() => '📣',
  GuildVoiceChannel() => '🔊',
  GuildForumChannel(:final isMedia) => isMedia ? '🖼' : '💬',
  _ => '?',
};
