import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs pin changes.
///
/// `CHANNEL_PINS_UPDATE` carries only the channel and the time of the
/// most recent pin, never the message that changed, so anything acting on
/// it has to re-list the channel's pins.
Future<void> handleChannelPinsUpdate(
  ChannelPinsUpdateEvent event,
  Bot bot,
  Logger logger,
) async {
  final page = await bot.messages.pins(event.channelId);
  logger.info(
    'Pins changed in ${event.channelId}: ${page.length} pinned, '
    'most recent at ${event.lastPinTimestamp}',
  );
}
