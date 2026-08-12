import 'package:fluxer_dart/fluxer_dart.dart';

/// Waits for the next message [userId] sends in [channelId], up to
/// [timeout] — `null` on timeout. The multi-turn counterpart to
/// `paginator.dart`'s reaction-await: same idea (filter a broadcast
/// gateway stream down to one conversation), applied to plain messages
/// instead of reactions, for a back-and-forth flow like `!setup`'s.
Future<String?> awaitReply(
  Bot bot, {
  required Snowflake channelId,
  required Snowflake userId,
  Duration timeout = const Duration(minutes: 2),
}) {
  final reply = bot.onMessageCreate
      .map((event) => event.message)
      .firstWhere((m) => m.channelId == channelId && m.author.id == userId)
      .then<String?>((m) => m.content);
  return reply.timeout(timeout, onTimeout: () => null);
}
