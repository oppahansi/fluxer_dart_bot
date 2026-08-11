import 'package:fluxer/fluxer.dart';

/// Replies "pong" to `!ping`, rate-limited to once per 5 seconds per user
/// via [cooldown] — demonstrates `CommandRouter` middleware.
Future<void> handlePing(CommandContext context) async {
  await context.reply(MessageBuilder(content: 'pong'));
}
