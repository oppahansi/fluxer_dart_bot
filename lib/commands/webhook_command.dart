import 'package:fluxer_dart/fluxer_dart.dart';

/// `!webhook create <name>` / `!webhook delete <webhook_id>`.
///
/// `create` demonstrates both webhook auth stories in one flow: the
/// creation call goes through the normal bot-token `RestClient`, but the
/// confirmation message is sent back through the fresh webhook itself
/// via [WebhookExecuteClient] — which carries no `Authorization` header
/// at all, just the webhook's own id+token in the URL. The token itself
/// is never posted to the channel; it's exactly the kind of secret a
/// bot leaking into chat would be a real vulnerability, demo or not.
Future<void> handleWebhook(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!webhook create|delete ...`'),
    );
    return;
  }

  final action = context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (action) {
      case 'create':
        if (rest.isEmpty) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!webhook create <name>`'),
          );
          return;
        }
        final name = rest.join(' ');
        final webhook = await context.bot.webhooks.createForChannel(
          context.message.channelId,
          name: name,
        );

        final executeClient = WebhookExecuteClient(
          transport: context.bot.rest.transport,
        );
        await executeClient.execute(
          webhook.id,
          webhook.token,
          content: 'Hello from webhook "$name"!',
          username: name,
        );

        await context.reply(
          MessageBuilder(
            content:
                'Created webhook "$name" (${webhook.id}) and sent a test '
                'message through it — its token is never printed here, '
                'treat it like a password.',
          ),
        );

      case 'delete':
        final webhookId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (webhookId == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!webhook delete <webhook_id>`'),
          );
          return;
        }
        await context.bot.webhooks.delete(Snowflake(webhookId));
        await context.reply(
          MessageBuilder(content: 'Deleted webhook $webhookId.'),
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
      MessageBuilder(content: 'Could not update webhooks: ${error.message}'),
    );
  }
}
