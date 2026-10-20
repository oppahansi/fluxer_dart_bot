import 'package:fluxer_dart/fluxer_dart.dart';

import 'api_error.dart';
import 'guild_context.dart';

/// `!vanity` / `!vanity <code>` / `!vanity clear` — reads or changes the
/// guild's vanity invite.
///
/// Setting a code needs the guild's `VANITY_URL` feature. Without it the
/// API rejects the request with a field error naming the feature, which
/// [describeApiError] passes through — an example of why the field
/// errors are worth showing.
Future<void> handleVanity(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  try {
    if (context.args.isEmpty) {
      final (:code, :uses) = await context.bot.guilds.vanityUrl(guildId);
      await context.reply(
        MessageBuilder(
          content: code == null
              ? 'No vanity invite.'
              : '`$code`, used $uses times.',
        ),
      );
      return;
    }
    final requested = context.args.first;
    final code = await context.bot.guilds.updateVanityUrl(
      guildId,
      requested == 'clear' ? null : requested,
    );
    await context.reply(
      MessageBuilder(
        content: code == null
            ? 'Vanity invite removed.'
            : 'Vanity invite is now `$code`.',
      ),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(
        content: 'Could not change it: ${describeApiError(error)}',
      ),
    );
  }
}
