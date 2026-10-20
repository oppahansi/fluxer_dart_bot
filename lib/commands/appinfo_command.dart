import 'package:fluxer_dart/fluxer_dart.dart';

/// `!appinfo` — the OAuth2 application this bot belongs to, from
/// `GET /applications/@me`.
///
/// The response also contains the bot's token; `BotApplication` never
/// decodes it, so it cannot end up in a reply or a log line by accident.
Future<void> handleAppInfo(CommandContext context) async {
  final app = await context.bot.users.application();
  await context.reply(
    MessageBuilder(
      content:
          '**${app.name}** `${app.id}`\n'
          'Owner: ${app.owner.displayName}\n'
          '${app.botPublic ? 'Anyone can add this bot.' : 'Only the owner can add this bot.'}'
          '${app.description == null ? '' : '\n${app.description}'}',
    ).allowedMentions(AllowedMentions.none),
  );
}
