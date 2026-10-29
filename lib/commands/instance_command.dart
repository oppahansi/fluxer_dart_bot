import 'package:fluxer_dart/fluxer_dart.dart';

/// `!instance` — reads the deployment's own discovery document.
///
/// `/.well-known/fluxer` is unauthenticated and carries no version
/// prefix. It is what lets one bot binary target any self-hosted
/// instance: resolve the domain here, then build the REST client from
/// `endpoints.api_public` and connect the gateway to `endpoints.gateway`
/// instead of hardcoding either.
Future<void> handleInstance(CommandContext context) async {
  final discovery = await discoverInstance(context.bot);

  final enabled = discovery.features.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .take(8)
      .join(', ');

  final notice = discovery.notice;
  final embed = EmbedBuilder()
      .title('Instance')
      .field('API version', '${discovery.apiCodeVersion}')
      .field('Public API', '${discovery.endpoints.apiPublic}')
      .field('Gateway', '${discovery.endpoints.gateway}')
      .field('Media', '${discovery.endpoints.media}')
      .field('Features', enabled.isEmpty ? 'none reported' : enabled)
      .field(
        'Guild badges',
        discovery.guildBadges.isEmpty
            ? 'none'
            : discovery.guildBadges.map((b) => b.name).join(', '),
      );
  if (notice != null) embed.field('Notice', notice.message);

  await context.reply(MessageBuilder().embed(embed.build()));
}

/// Fetches the discovery document of the deployment [bot] talks to.
Future<InstanceDiscovery> discoverInstance(Bot bot) {
  final transport = bot.rest.transport;
  final origin = transport is PackageHttpTransport
      ? transport.baseUrl
      : Uri.parse('https://fluxer.app');
  return const InstanceRestManager().discover(origin.replace(path: ''));
}
