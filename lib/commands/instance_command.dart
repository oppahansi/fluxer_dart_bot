import 'package:fluxer_dart/fluxer_dart.dart';

/// `!instance` — reads the deployment's own discovery document.
///
/// `/.well-known/fluxer` is unauthenticated and carries no version
/// prefix. It is what lets one bot binary target any self-hosted
/// instance: resolve the domain here, then build the REST client from
/// `endpoints.api_public` and connect the gateway to `endpoints.gateway`
/// instead of hardcoding either.
Future<void> handleInstance(CommandContext context) async {
  final origin = context.bot.rest.transport is PackageHttpTransport
      ? (context.bot.rest.transport as PackageHttpTransport).baseUrl
      : Uri.parse('https://fluxer.app');

  final discovery = await const InstanceRestManager().discover(
    origin.replace(path: ''),
  );

  final enabled = discovery.features.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .take(8)
      .join(', ');

  await context.reply(
    MessageBuilder().embed(
      EmbedBuilder()
          .title('Instance')
          .field('API version', '${discovery.apiCodeVersion}')
          .field('Public API', '${discovery.endpoints.apiPublic}')
          .field('Gateway', '${discovery.endpoints.gateway}')
          .field('Media', '${discovery.endpoints.media}')
          .field('Features', enabled.isEmpty ? 'none reported' : enabled)
          .build(),
    ),
  );
}
