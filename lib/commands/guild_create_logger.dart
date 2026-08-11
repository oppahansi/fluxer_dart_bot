import 'package:fluxer/fluxer.dart';

/// Logs every guild the bot can see, once per `GUILD_CREATE` dispatch
/// (sent for each guild on connect, and again if the bot joins a new one
/// afterwards). A second, even smaller example alongside
/// [handlePingCommand] — demonstrates `onGuildCreate` rather than
/// `onMessageCreate`.
///
/// Takes [logger] rather than calling `print` directly, so this goes
/// through the same `Logger` (and respects the same `minLevel`) as
/// everything else in the bot — one logging pathway, not two.
void handleGuildCreate(GuildCreateEvent event, Logger logger) {
  final guild = event.guild;
  logger.info(
    '[guild] ${guild.name} ($guild) — ${guild.memberCount ?? '?'} members, ${guild.roles.length} roles',
  );
}
