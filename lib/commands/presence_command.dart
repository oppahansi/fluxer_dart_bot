import 'package:fluxer_dart/fluxer_dart.dart';

const _statuses = <String, PresenceStatus>{
  'online': PresenceStatus.online,
  'idle': PresenceStatus.idle,
  'dnd': PresenceStatus.doNotDisturb,
  'invisible': PresenceStatus.invisible,
};

/// `!presence <online|idle|dnd|invisible> [status text]` — replaces the
/// bot's published presence.
///
/// This is a gateway command rather than a REST call, so it returns
/// nothing and is rate limited to five updates per 20 seconds. Passing no
/// status text clears any custom status currently set, which needs an
/// explicit null on the wire rather than an omitted field.
Future<void> handlePresence(CommandContext context) async {
  final requested = context.args.isEmpty ? '' : context.args.first;
  final status = _statuses[requested.toLowerCase()];

  if (status == null) {
    await context.reply(
      MessageBuilder(
        content: 'Usage: `!presence <${_statuses.keys.join('|')}> [text]`',
      ),
    );
    return;
  }

  final text = context.args.skip(1).join(' ');
  context.bot.updatePresence(
    text.isEmpty
        ? Presence.clearCustomStatus(status)
        : Presence(
            status: status,
            customStatus: CustomStatus(text: text),
          ),
  );

  await context.reply(
    MessageBuilder(
      content: text.isEmpty
          ? 'Presence set to `$requested`, custom status cleared.'
          : 'Presence set to `$requested` with status "$text".',
    ),
  );
}
