import 'package:fluxer_dart/fluxer_dart.dart';

/// Sends a multi-field rich embed, demonstrating `EmbedBuilder`.
Future<void> handleEmbed(CommandContext context) async {
  final embed = EmbedBuilder()
      .title('fluxer_dart example embed')
      .description('Built with EmbedBuilder: fields, a footer, and a color.')
      .color(0x4641d9)
      .field('Field one', 'Inline value', inline: true)
      .field('Field two', 'Also inline', inline: true)
      .footer('Sent by fluxer_dart_bot')
      .build();

  await context.bot.messages.send(
    context.message.channelId,
    MessageBuilder().embed(embed),
  );
}
