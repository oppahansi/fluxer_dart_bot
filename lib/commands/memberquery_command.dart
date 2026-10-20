import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!memberquery [prefix]` — looks members up over the gateway with
/// `Bot.queryMembers`, with their presences.
///
/// The gateway is the only place a bot learns who is online: a REST
/// member has no presence. Without a prefix this asks for the whole
/// member list, which a bot may do once per guild every 30 seconds; a
/// second request inside that window is refused, and the refusal comes
/// back as a [FluxerGatewayRateLimitException] carrying the wait.
Future<void> handleMemberQuery(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final prefix = context.args.join(' ');
  try {
    final (:members, :presences) = await context.bot.queryMembers(
      guildId,
      query: prefix,
      limit: prefix.isEmpty ? 0 : 20,
      presences: true,
    );
    if (members.isEmpty) {
      await context.reply(MessageBuilder(content: 'Nobody matches `$prefix`.'));
      return;
    }
    final status = {for (final p in presences) p.user.id: p.status};
    final lines = members
        .take(25)
        .map(
          (m) =>
              '- ${m.displayName} `${m.user.id}` — '
              '${status[m.user.id]?.value ?? 'offline'}',
        );
    await context.reply(
      MessageBuilder(
        content:
            '${members.length} member(s), ${presences.length} online'
            '${members.length > 25 ? ', first 25' : ''}:\n${lines.join('\n')}',
      ),
    );
  } on FluxerGatewayRateLimitException catch (error) {
    await context.reply(
      MessageBuilder(
        content:
            'The full member list was requested too recently. Try again in '
            '${(error.retryAfter.inMilliseconds / 1000).ceil()} s, or pass '
            'a name prefix.',
      ),
    );
  }
}
