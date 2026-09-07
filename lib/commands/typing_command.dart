import 'package:fluxer_dart/fluxer_dart.dart';

/// `!typing` — shows the typing indicator, then answers once the work it
/// stands in for is done.
///
/// The indicator lasts about ten seconds and there is no route to stop it
/// early, so a handler that takes longer re-triggers it rather than
/// sending once up front.
Future<void> handleTyping(CommandContext context) async {
  await context.bot.messages.triggerTyping(context.message.channelId);

  // Stands in for whatever slow work a real command would do here.
  await Future<void>.delayed(const Duration(seconds: 2));

  await context.reply(
    MessageBuilder(content: 'Done — the indicator ran while that worked.'),
  );
}
