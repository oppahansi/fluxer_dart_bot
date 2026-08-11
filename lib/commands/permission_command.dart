import 'package:fluxer_dart/fluxer_dart.dart';

/// `!permission set` and `!permission clear` set or remove a channel
/// permission overwrite for a role (role ID plus, for `set`, a
/// [PermissionFlag] name). Role overwrites only, to keep argument
/// parsing simple — a member overwrite would need a way to tell a role
/// id from a user id, which isn't worth the complexity for a demo
/// command.
///
/// `set` only ever grants (never denies) the named permission, and
/// replaces any existing overwrite for that role rather than merging —
/// `ChannelRestManager.setPermissionOverwrite` is a PUT, not a patch.
Future<void> handlePermission(CommandContext context) async {
  if (context.args.length < 2) {
    await context.reply(
      MessageBuilder(
        content:
            'Usage: `!permission set <role_id> <PermissionFlagName>` or '
            '`!permission clear <role_id>`',
      ),
    );
    return;
  }

  final action = context.args[0];
  final channelId = context.message.channelId;

  switch (action) {
    case 'set':
      if (context.args.length < 3) {
        await context.reply(
          MessageBuilder(
            content: 'Usage: `!permission set <role_id> <PermissionFlagName>`',
          ),
        );
        return;
      }
      final roleId = int.tryParse(context.args[1]);
      final flag = PermissionFlag.values
          .where((f) => f.name == context.args[2])
          .firstOrNull;
      if (roleId == null || flag == null) {
        await context.reply(
          MessageBuilder(
            content:
                'Could not parse a role id and a known permission name '
                '(e.g. `sendMessages`, `manageMessages`).',
          ),
        );
        return;
      }
      await context.bot.channels.setPermissionOverwrite(
        channelId,
        Snowflake(roleId),
        PermissionOverwrite(
          type: PermissionOverwriteType.role,
          allow: Permissions.none.withFlag(flag),
          deny: Permissions.none,
        ),
      );

    case 'clear':
      final roleId = int.tryParse(context.args[1]);
      if (roleId == null) {
        await context.reply(
          MessageBuilder(content: 'Usage: `!permission clear <role_id>`'),
        );
        return;
      }
      await context.bot.channels.deletePermissionOverwrite(
        channelId,
        Snowflake(roleId),
      );

    default:
      await context.reply(
        MessageBuilder(content: 'Unknown action `$action`. Use set or clear.'),
      );
  }
}
