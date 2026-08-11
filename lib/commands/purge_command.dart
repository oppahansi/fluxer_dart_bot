import 'package:fluxer_dart/fluxer_dart.dart';

/// Bulk-deletes the last `!purge <count>` messages in the channel
/// (1-100). The first genuinely destructive example command — no
/// permission gate yet, since `requireGuildPermission` middleware
/// doesn't exist until a later milestone; add `manageMessages` gating to
/// this command's registration once it does.
///
/// Catches [FluxerApiException] itself rather than letting it propagate
/// to `runGuarded`'s catch-all: confirmed live that a bot without
/// `manageMessages` gets a `403 MISSING_PERMISSIONS` here, and a raw
/// logged stack trace is a worse demonstration of failure handling than
/// a reply explaining what happened.
Future<void> handlePurge(CommandContext context) async {
  final count = context.args.isEmpty ? null : int.tryParse(context.args.first);
  if (count == null || count < 1 || count > 100) {
    await context.reply(MessageBuilder(content: 'Usage: `!purge <1-100>`'));
    return;
  }

  final channelId = context.message.channelId;
  try {
    final messages = await context.bot.messages.list(channelId, limit: count);
    if (messages.isEmpty) return;

    await context.bot.messages.bulkDelete(
      channelId,
      messages.map((m) => m.id).toList(),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not purge messages: ${error.message}'),
    );
  }
}
