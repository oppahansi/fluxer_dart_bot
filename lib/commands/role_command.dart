import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

/// `!role list|create|delete|rename|color|hoist|move|add|remove` —
/// requires `manageRoles`. One command with an action sub-argument, same
/// reasoning as `!channel`.
///
/// `rename`, `color` and `hoist` go through [GuildRoleUpdateBuilder],
/// which sends only the fields it was given. `move` uses the reorder
/// route, answered by `GUILD_ROLE_UPDATE_BULK` for every role that
/// shifted.
Future<void> handleRole(CommandContext context) async {
  if (context.args.isEmpty) {
    await context.reply(
      MessageBuilder(
        content:
            'Usage: `!role list|create|delete|rename|color|hoist|move|'
            'add|remove ...`',
      ),
    );
    return;
  }

  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final action = context.args.first;
  final rest = context.args.skip(1).toList();

  try {
    switch (action) {
      case 'list':
        final roles = await context.bot.roles.list(guildId)
          ..sort((a, b) => b.position.compareTo(a.position));
        await context.reply(
          MessageBuilder(
            content: roles
                .map(
                  (r) =>
                      '- ${r.name} `${r.id}` pos ${r.position}'
                      '${r.hoist ? ', hoisted' : ''}'
                      '${r.color != 0 ? ', #${r.color.toRadixString(16).padLeft(6, '0')}' : ''}',
                )
                .join('\n'),
          ),
        );

      case 'rename' || 'color' || 'hoist':
        final roleId = rest.isEmpty ? null : int.tryParse(rest.first);
        final value = rest.skip(1).join(' ');
        final update = switch (action) {
          'rename' when value.isNotEmpty => GuildRoleUpdateBuilder().name(
            value,
          ),
          'color' => switch (int.tryParse(
            value.replaceFirst('#', ''),
            radix: 16,
          )) {
            final color? => GuildRoleUpdateBuilder().color(color),
            null => null,
          },
          'hoist' when value == 'on' || value == 'off' =>
            GuildRoleUpdateBuilder().hoist(value == 'on'),
          _ => null,
        };
        if (roleId == null || update == null) {
          final hint = switch (action) {
            'rename' => '<name>',
            'color' => '<#rrggbb>',
            _ => 'on|off',
          };
          await context.reply(
            MessageBuilder(content: 'Usage: `!role $action <role_id> $hint`'),
          );
          return;
        }
        final role = await context.bot.roles.update(
          guildId,
          Snowflake(roleId),
          update,
        );
        await context.reply(
          MessageBuilder(
            content:
                'Updated "${role.name}": colour '
                '#${role.color.toRadixString(16).padLeft(6, '0')}, '
                '${role.hoist ? 'hoisted' : 'not hoisted'}.',
          ),
        );

      case 'move':
        final roleId = rest.isEmpty ? null : int.tryParse(rest.first);
        final position = rest.length < 2 ? null : int.tryParse(rest[1]);
        if (roleId == null || position == null) {
          await context.reply(
            MessageBuilder(content: 'Usage: `!role move <role_id> <position>`'),
          );
          return;
        }
        await context.bot.roles.updatePositions(guildId, {
          Snowflake(roleId): position,
        });
        final moved = (await context.bot.roles.list(
          guildId,
        )).firstWhere((r) => r.id == Snowflake(roleId));
        await context.reply(
          MessageBuilder(
            content: 'Moved "${moved.name}" to position ${moved.position}.',
          ),
        );

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
                'Unknown action `$action`. Use list, create, delete, rename, '
                'color, hoist, move, add, or remove.',
          ),
        );
    }
  } on FluxerApiException catch (error) {
    await context.reply(
      MessageBuilder(content: 'Could not update roles: ${error.message}'),
    );
  }
}
