import 'package:fluxer_dart/fluxer_dart.dart';

/// `!slowmode <seconds>` — sets the current channel's per-user message
/// rate limit. `0` turns it off.
Future<void> handleSlowmode(CommandContext context) async {
  final seconds = context.args.isEmpty
      ? null
      : int.tryParse(context.args.first);
  if (seconds == null || seconds < 0) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!slowmode <seconds>` (0 to disable)'),
    );
    return;
  }

  final channelId = context.message.channelId;
  final current = await context.bot.channel(channelId);
  final currentType = current.type;
  if (currentType == null) {
    await context.reply(
      MessageBuilder(
        content:
            "This channel's type isn't recognized, so it can't be safely updated.",
      ),
    );
    return;
  }

  await context.bot.channels.update(
    channelId,
    ChannelUpdateBuilder(currentType).rateLimitPerUser(seconds),
  );
}
