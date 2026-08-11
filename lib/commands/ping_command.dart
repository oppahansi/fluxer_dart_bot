import 'package:fluxer/fluxer.dart';

/// Replies "pong" to a `!ping` message.
///
/// fluxer.dart doesn't have a formal command router yet (that's a later
/// milestone — see this ecosystem's roadmap), so for now a "command" is
/// just a plain function taking the event and the [Bot] it needs to
/// respond, kept in its own file under `lib/commands/` so the pattern for
/// adding more of these is obvious once a real router does land.
Future<void> handlePingCommand(Bot bot, MessageCreateEvent event) async {
  final message = event.message;
  if (message.author.bot) return;
  if (message.content.trim() != '!ping') return;

  await bot.messages.send(message.channelId, MessageBuilder(content: 'pong'));
}
