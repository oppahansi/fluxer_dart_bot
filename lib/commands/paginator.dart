import 'dart:async';

import 'package:fluxer_dart/fluxer_dart.dart';

const _previousEmoji = '◀️';
const _nextEmoji = '▶️';

/// Sends [render]'s first page, then — if there's more than one page —
/// attaches ◀️/▶️ reactions and lets the triggering user page through the
/// rest by clicking them, editing the same message in place rather than
/// sending a new one per page.
///
/// The one place in this bot a "framework-shaped" helper earns its keep:
/// every other command sends one reply and is done, but pagination is
/// genuinely the same dance (attach reactions, filter
/// `MESSAGE_REACTION_ADD` down to this message, edit, remove the click)
/// no matter what's being paged.
///
/// Deliberately simple, not a general framework feature: listens for
/// [idleTimeout] of inactivity before giving up (no persistence across
/// bot restarts, no re-arming on other messages) — enough for a demo,
/// not a production pagination system.
Future<void> sendPaginated(
  CommandContext context, {
  required int totalPages,
  required String Function(int page) render,
  Duration idleTimeout = const Duration(minutes: 5),
}) async {
  final message = await context.reply(MessageBuilder(content: render(0)));
  if (totalPages <= 1) return;

  final channelId = message.channelId;
  await context.bot.messages.addReaction(channelId, message.id, _previousEmoji);
  await context.bot.messages.addReaction(channelId, message.id, _nextEmoji);

  var currentPage = 0;
  Timer? idleTimer;
  late StreamSubscription<MessageReactionAddEvent> subscription;

  void resetIdleTimer() {
    idleTimer?.cancel();
    idleTimer = Timer(idleTimeout, () => subscription.cancel());
  }

  subscription = context.bot.onMessageReactionAdd
      .where((event) => event.messageId == message.id)
      .listen((event) async {
        if (event.userId == context.bot.selfId) return;
        final emoji = event.emoji.name;

        if (emoji == _previousEmoji && currentPage > 0) {
          currentPage--;
        } else if (emoji == _nextEmoji && currentPage < totalPages - 1) {
          currentPage++;
        }

        if (emoji != null) {
          await context.bot.messages.removeReaction(
            channelId,
            message.id,
            emoji,
            event.userId,
          );
        }
        await context.bot.messages.edit(
          channelId,
          message.id,
          MessageBuilder(content: render(currentPage)),
        );
        resetIdleTimer();
      });

  resetIdleTimer();
}
