import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!membersearch <query>` — finds members by username, global name or
/// nickname.
///
/// Backed by a search index rather than the member list, which is what
/// makes it usable on a large guild where paging every member is not.
/// The index can still be building, in which case an empty result is not
/// authoritative — hence the explicit check.
Future<void> handleMemberSearch(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!membersearch <query>`'),
    );
    return;
  }

  final query = context.args.join(' ');
  final page = await context.bot.guilds.searchMembers(
    guildId,
    query: query,
    limit: 10,
  );

  if (page.indexing) {
    await context.reply(
      MessageBuilder(
        content: 'This guild is still being indexed; results are incomplete.',
      ),
    );
    return;
  }

  if (page.members.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'No members matched "$query".'),
    );
    return;
  }

  final lines = page.members
      .map((m) => '- ${m.displayName} (`${m.userId}`)')
      .join('\n');
  await context.reply(
    MessageBuilder(
      content:
          'Showing ${page.members.length} of ${page.totalResultCount} '
          'match(es) for "$query":\n$lines',
    ),
  );
}
