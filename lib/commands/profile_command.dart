import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!profile [user_id]` — a user's profile, with their guild profile and
/// the guilds they share with this bot.
///
/// Naming the guild in `UserRestManager.profile` adds the member and the
/// guild-specific bio and pronouns, which override the account-wide ones
/// inside that guild.
Future<void> handleProfile(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final userId = context.args.isEmpty
      ? context.message.author.id
      : Snowflake(int.tryParse(context.args.first) ?? 0);
  try {
    final profile = await context.bot.users.profile(
      userId,
      guildId: guildId,
      withMutualGuilds: true,
    );
    final bio = profile.guildBio ?? profile.bio;
    final pronouns = profile.guildPronouns ?? profile.pronouns;
    final badges = profile.badges.isEmpty
        ? 'No badges.'
        : 'Badges: ${profile.badges.map((b) => b.caption ?? b.label).join(', ')}.';
    await context.reply(
      MessageBuilder(
        content:
            '**${profile.user.displayName}** `${profile.user.id}`'
            '${pronouns == null ? '' : ' ($pronouns)'}\n'
            '${bio ?? 'No bio.'}\n'
            '$badges\n'
            '${profile.guildMember == null ? 'Not a member here.' : 'Member since ${profile.guildMember!.joinedAt.toIso8601String().substring(0, 10)}.'} '
            'Shares ${profile.mutualGuilds.length} guild(s) with this bot.',
      ).allowedMentions(AllowedMentions.none),
    );
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'No profile: ${error.message}'),
    );
  }
}
