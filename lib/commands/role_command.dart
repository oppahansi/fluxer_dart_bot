import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!role create`, `!role delete`, `!role add`, and `!role remove`
/// (a role/user id pair for the last two) — requires `manageRoles`. One
/// command with an action sub-argument, same reasoning as `!channel`.
Future<void> handleRole(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(content: 'Usage: `!role create|delete|add|remove ...`'),
    );
    return;
  }

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final action = context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (action) {
      case 'create':
        if (rest.isEmpty) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!role create <name>`'),
          );
          return;
        }
        final role = await context.bot.roles.create(
          guildId,
          name: rest.join(' '),
        );
        await context.reply(
          MessageBuilder(content: 'Created role "${role.name}" (${role.id}).'),
        );

      case 'delete':
        final roleId = rest.isEmpty ? null : int.tryParse(rest.first);
        if (roleId == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!role delete <role_id>`'),
          );
          return;
        }
        await context.bot.roles.delete(guildId, Snowflake(roleId));
        await context.reply(MessageBuilder(content: 'Deleted role $roleId.'));

      case 'add':
      case 'remove':
        if (rest.length < 2) {
          await context.reply(
            MessageBuilder(
              content: 'Usage: `!role $action <user_id> <role_id>`',
            ),
          );
          return;
        }
        final userId = int.tryParse(rest[0]);
        final roleId = int.tryParse(rest[1]);
        if (userId == null || roleId == null) {
          await context.reply(
            MessageBuilder(content: 'Could not parse a user id and a role id.'),
          );
          return;
        }
        if (action == 'add') {
          await context.bot.members.addRole(
            guildId,
            Snowflake(userId),
            Snowflake(roleId),
          );
        } else {
          await context.bot.members.removeRole(
            guildId,
            Snowflake(userId),
            Snowflake(roleId),
          );
        }
        await context.reply(
          MessageBuilder(
            content: action == 'add'
                ? 'Added role $roleId to user $userId.'
                : 'Removed role $roleId from user $userId.',
          ),
        );

      default:
        await context.reply(
          MessageBuilder(
            content:
                'Unknown action `$action`. Use create, delete, add, or remove.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update roles: ${error.message}'),
    );
  }
}
