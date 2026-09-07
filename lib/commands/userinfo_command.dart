import 'package:fluxer_dart/fluxer_dart.dart';

/// `!userinfo [user id]` — shows a user, defaulting to the caller.
///
/// Uses `Bot.fetchUser`, which answers from cache when the user has
/// already been seen and falls back to `GET /users/{id}` otherwise.
Future<void> handleUserInfo(CommandContext context) async {
  final requested = context.args.isEmpty ? null : context.args.first;
  final userId = requested == null
      ? context.message.author.id
      : Snowflake.parse(requested.replaceAll(RegExp(r'[<@>]'), ''));

  final user = await context.bot.fetchUser(userId);

  await context.reply(
    MessageBuilder().embed(
      EmbedBuilder()
          .title('${user.username}#${user.discriminator}')
          .field('ID', '${user.id}')
          .field('Display name', user.globalName ?? user.username)
          .field('Bot', user.bot ? 'yes' : 'no')
          .field('Account created', '${user.id.timestamp}')
          .build(),
    ),
  );
}
