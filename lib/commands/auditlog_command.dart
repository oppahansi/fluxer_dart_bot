import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!auditlog [count]` (default 5, max 20) — requires `viewAuditLog`.
/// Displays each entry's action type and who did it; `options`/`changes`
/// stay unshown — see `GuildAuditLogEntry`'s own note on why those are
/// raw maps rather than a typed variant per action.
Future<void> handleAuditLog(CommandContext context) async {
  final count = context.args.isEmpty
      ? 5
      : (int.tryParse(context.args.first) ?? 5);
  final limit = count.clamp(1, 20);

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  try {
    final entries = await context.bot.guilds.getAuditLogs(
      guildId,
      limit: limit,
    );
    if (entries.isEmpty) {
      await context.reply(MessageBuilder(content: 'No audit log entries.'));
      return;
    }
    final lines = entries.map(
      (e) =>
          '- actionType=${e.actionType} user=${e.userId} target=${e.targetId}'
          '${e.reason != null ? ' reason="${e.reason}"' : ''}',
    );
    await context.reply(
      MessageBuilder(content: 'Recent audit log entries:\n${lines.join('\n')}'),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not fetch audit logs: ${error.message}'),
    );
  }
}
