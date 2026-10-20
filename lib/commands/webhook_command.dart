import 'package:fluxer_dart/fluxer_dart.dart';

/// `!webhook create <name>` / `!webhook relay <text>` /
/// `!webhook delete <webhook_id>`.
///
/// `create` demonstrates both webhook auth stories in one flow: the
/// creation call goes through the normal bot-token `RestClient`, but the
/// confirmation message is sent back through the fresh webhook itself
/// via [WebhookExecuteClient] — which carries no `Authorization` header
/// at all, just the webhook's own id+token in the URL. The token itself
/// is never posted to the channel; it's exactly the kind of secret a
/// bot leaking into chat would be a real vulnerability, demo or not.
///
/// `relay` walks every route the token alone can call: it posts with
/// `executeAndWait` to get the message back, edits and re-reads it, posts
/// into a thread of this channel with `threadId`, renames the webhook,
/// and finally deletes it — all through `Bot.webhookTokens`, none of it
/// with the bot's own credentials.
Future<void> handleWebhook(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!webhook create|relay|delete ...`'),
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

        // A webhook created here is always an incoming one, so it has a
        // token; a channel follower webhook would not, and cannot be
        // posted to at all.
        final token = webhook.token;
        if (token == null) {
          await context.reply(
            MessageBuilder(
              content:
                  'Created webhook "$name" (${webhook.id}), but it carries '
                  'no token, so nothing can be posted through it.',
            ),
          );
          return;
        }

        final executeClient = WebhookExecuteClient(
          transport: context.bot.rest.transport,
        );
        await executeClient.execute(
          webhook.id,
          token,
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

      case 'relay':
        if (rest.isEmpty) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!webhook relay <text>`'),
          );
          return;
        }
        final channelId = context.message.channelId;
        final created = await context.bot.webhooks.createForChannel(
          channelId,
          name: 'relay',
        );
        final hookToken = created.token!;
        final tokens = context.bot.webhookTokens;
        final sent = await tokens.executeAndWait(
          created.id,
          hookToken,
          content: rest.join(' '),
          username: context.message.author.username,
          allowedMentions: AllowedMentions.none,
        );
        await tokens.editMessage(
          created.id,
          hookToken,
          sent.id,
          content: '${sent.content} (edited through the webhook token)',
        );
        final reread = await tokens.getMessage(created.id, hookToken, sent.id);
        final thread = await context.bot.threads.start(
          channelId,
          name: 'relay thread',
        );
        await tokens.execute(
          created.id,
          hookToken,
          content: 'Posted into a thread with thread_id.',
          threadId: thread.id,
        );
        final renamed = await tokens.update(
          created.id,
          hookToken,
          name: 'relay (renamed)',
        );
        await tokens.delete(created.id, hookToken);
        await context.reply(
          MessageBuilder(
            content:
                'Relayed as message ${reread.id} (now "${reread.content}"), '
                'posted into <#${thread.id}>, renamed the webhook to '
                '"${renamed.name}" and deleted it — all with its token.',
          ).allowedMentions(AllowedMentions.none),
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
            content: 'Unknown action `$action`. Use create, relay or delete.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update webhooks: ${error.message}'),
    );
  }
}
