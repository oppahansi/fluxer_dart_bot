import 'package:fluxer/fluxer.dart';

/// Logs every guild the bot can see, once per `GUILD_CREATE` dispatch
/// (sent for each guild on connect, and again if the bot joins a new one
/// afterwards). A second, even smaller example alongside
/// [handlePingCommand] — demonstrates `onGuildCreate` rather than
/// `onMessageCreate`.
void handleGuildCreate(GuildCreateEvent event) {
  final guild = event.guild;
  print(
    '[guild] ${guild.name} ($guild) — ${guild.memberCount ?? '?'} members, ${guild.roles.length} roles',
  );
}
