import 'package:fluxer_dart/fluxer_dart.dart';

/// `!invite create` / `!invite delete <code>` — `create` takes no
/// further arguments and lets the server pick its own defaults for
/// max uses/age (`InviteRestManager.createForChannel` only sends
/// `max_uses`/`max_age`/`unique` when explicitly given).
Future<void> handleInvite(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!invite create|delete ...`'),
    );
    return;
  }

  final action = context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (action) {
      case 'create':
        final invite = await context.bot.invites.createForChannel(
          context.message.channelId,
        );
        await context.reply(
          MessageBuilder(content: 'Created invite: `${invite.code}`'),
        );

      case 'delete':
        if (rest.isEmpty) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!invite delete <code>`'),
          );
          return;
        }
        await context.bot.invites.delete(rest.first);
        await context.reply(
          MessageBuilder(content: 'Deleted invite `${rest.first}`.'),
        );

      default:
        await context.reply(
          MessageBuilder(
            content: 'Unknown action `$action`. Use create or delete.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update invites: ${error.message}'),
    );
  }
}
