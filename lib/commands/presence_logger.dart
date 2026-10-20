import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs presence and voice changes.
///
/// Presences arrive only for members this bot subscribed to (see
/// `!watch`); voice state changes arrive for every voice channel the bot
/// can view, without any subscription.
void registerPresenceLoggers(Bot bot, Logger logger) {
  bot.onPresenceUpdate.listen((event) {
    final presence = event.presence;
    logger.info(
      'Presence: ${presence.user.displayName} is now '
      '${presence.status.value}'
      '${presence.customStatus?.text != null ? ' — "${presence.customStatus!.text}"' : ''}',
    );
  });

  bot.onVoiceStateUpdate.listen((event) {
    final state = event.state;
    logger.info(
      state.channelId == null
          ? 'Voice: ${state.userId} left (${state.connectionId})'
          : 'Voice: ${state.userId} in ${state.channelId} '
                '(${state.connectionId})',
    );
  });

  bot.onGuildSync.listen((event) {
    logger.info(
      'Guild ${event.guild.name} resynced: ${event.channels.length} '
      'channels, ${event.voiceStates.length} voice connection(s)',
    );
  });
}
