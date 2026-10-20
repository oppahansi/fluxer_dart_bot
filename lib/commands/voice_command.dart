import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!voice` — who is connected to voice in this guild, from `Bot`'s voice
/// state cache.
///
/// No request is made: the guild's voice states arrive with
/// `GUILD_CREATE`, and `VOICE_STATE_UPDATE` keeps them current. A user can
/// hold several connections at once, so each line is one connection.
Future<void> handleVoice(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final states = context.bot.voiceStates(guildId);
  if (states.isEmpty) {
    await context.reply(MessageBuilder(content: 'Nobody is in voice.'));
    return;
  }
  final lines = [
    for (final state in states)
      '- ${state.member?.displayName ?? state.userId} in <#${state.channelId}>'
          '${state.selfMute ? ' 🔇' : ''}${state.selfDeaf ? ' 🙉' : ''}'
          '${state.selfStream ? ' 📺' : ''}',
  ];
  await context.reply(
    MessageBuilder(
      content: '${states.length} voice connection(s):\n${lines.join('\n')}',
    ),
  );
}
