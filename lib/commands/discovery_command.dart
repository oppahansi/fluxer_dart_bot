import 'package:fluxer_dart/fluxer_dart.dart';

import 'api_error.dart';
import 'guild_context.dart';

const _usage =
    'Usage: `!discovery categories`, `!discovery browse [query]`, '
    '`!discovery status`, `!discovery apply <category id> <description>`, '
    '`!discovery withdraw`';

/// `!discovery categories|browse|status|apply|withdraw` — guild
/// discovery, through `Bot.discovery`.
///
/// `browse` lists guilds that are already listed; `status`, `apply` and
/// `withdraw` manage this guild's own application, which starts out
/// pending review by the instance's staff.
Future<void> handleDiscovery(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final action = context.args.isEmpty ? '' : context.args.first;
  final rest = context.args.skip(1).toList();
  final discovery = context.bot.discovery;

  try {
    switch (action) {
      case 'categories':
        final categories = await discovery.categories();
        await context.reply(
          MessageBuilder(
            content: categories.map((c) => '`${c.id}` ${c.name}').join('\n'),
          ),
        );

      case 'browse':
        final page = await discovery.search(
          query: rest.isEmpty ? null : rest.join(' '),
          limit: 10,
        );
        await context.reply(
          MessageBuilder(
            content: page.guilds.isEmpty
                ? 'No listed guilds match.'
                : '${page.total} listed guild(s):\n'
                      '${page.guilds.map((g) => '- ${g.name}: ${g.onlineCount} online of ${g.memberCount}').join('\n')}',
          ),
        );

      case 'status':
        final status = await discovery.status(guildId);
        final application = status.application;
        await context.reply(
          MessageBuilder(
            content:
                '${status.eligible ? 'Eligible' : 'Not eligible'} '
                '(needs ${status.minMemberCount} members). '
                '${application == null ? 'No application.' : 'Application: ${application.status}, applied ${application.appliedAt.toIso8601String()}.'}',
          ),
        );

      case 'apply' when rest.length >= 2 && int.tryParse(rest.first) != null:
        final application = await discovery.apply(
          guildId,
          categoryType: int.parse(rest.first),
          description: rest.skip(1).join(' '),
        );
        await context.reply(
          MessageBuilder(content: 'Applied; status is ${application.status}.'),
        );

      case 'withdraw':
        await discovery.withdraw(guildId);
        await context.reply(MessageBuilder(content: 'Application withdrawn.'));

      default:
        await context.reply(MessageBuilder(content: _usage));
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Discovery failed: ${describeApiError(error)}'),
    );
  }
}
