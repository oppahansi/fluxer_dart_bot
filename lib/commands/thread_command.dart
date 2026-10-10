import 'package:fluxer_dart/fluxer_dart.dart';

import 'guild_context.dart';

const _usage =
    'Usage: `!thread start|private <name>`, `!thread list`, or inside a '
    'thread `!thread rename <name>|archive|lock|members`';

/// `!thread start|private|list|rename|archive|lock|members` — threads.
///
/// A thread is a channel, so nothing here needs a separate way to send
/// to one: `context.reply` inside a thread already posts into it, and
/// `bot.channel(id)` returns it as a [ThreadChannel].
///
/// `start` shows both ways to open a public thread. Used as a reply it
/// starts the thread from the replied-to message, and the thread takes
/// that message's id; otherwise it starts one with no source message.
///
/// The subcommands that act on an existing thread read it from the
/// channel the command was sent in, so they are run inside the thread.
Future<void> handleThread(CommandContext context) async {
  final guildId = await requireGuildContext(context);
  if (guildId == null) return;

  final subcommand = context.args.isEmpty ? '' : context.args.first;
  final name = context.args.skip(1).join(' ');
  final channelId = context.message.channelId;
  final threads = context.bot.threads;

  try {
    switch (subcommand) {
      case 'start':
        if (name.isEmpty) {
          await context.reply(MessageBuilder(content: _usage));
          return;
        }
        final source = context.message.messageReference?.messageId;
        final thread = source == null
            ? await threads.start(channelId, name: name)
            : await threads.startFromMessage(channelId, source, name: name);
        await context.bot.messages.send(
          thread.id,
          MessageBuilder(
            content: 'Thread started by <@${context.message.author.id}>.',
          ).allowedMentions(AllowedMentions.none),
        );

      case 'private':
        if (name.isEmpty) {
          await context.reply(MessageBuilder(content: _usage));
          return;
        }
        final thread = await threads.start(
          channelId,
          name: name,
          type: ChannelType.privateThread,
        );
        // A private thread is visible only to its members, and the bot
        // is the only one so far.
        await threads.addMember(thread.id, context.message.author.id);

      case 'list':
        final active = await threads.listActive(guildId);
        await context.reply(
          MessageBuilder(
            content: active.threads.isEmpty
                ? 'No active threads.'
                : active.threads
                      .map(
                        (t) =>
                            '- <#${t.id}> in <#${t.parentId}>, '
                            '${t.messageCount} message(s)'
                            '${active.memberFor(t.id) == null ? '' : ' (joined)'}',
                      )
                      .join('\n'),
          ),
        );

      case 'rename' || 'archive' || 'lock' || 'members':
        // Fetched rather than read through the cache: `lock` toggles on
        // the thread's current state, and a cached copy is only as fresh
        // as the last THREAD_UPDATE this session received.
        final thread = await context.bot.channels.get(channelId);
        if (thread is! ThreadChannel) {
          await context.reply(
            MessageBuilder(content: 'Run `!thread $subcommand` in a thread.'),
          );
          return;
        }
        await _actOnThread(context, thread, subcommand, name);

      default:
        await context.reply(MessageBuilder(content: _usage));
    }
  } on FluxerApiException catch (e) {
    await context.reply(
      MessageBuilder(content: 'That failed: ${e.message} (`${e.errorCode}`)'),
    );
  }
}

Future<void> _actOnThread(
  CommandContext context,
  ThreadChannel thread,
  String subcommand,
  String name,
) async {
  final threads = context.bot.threads;
  final reason = 'Requested by ${context.message.author.username}';

  switch (subcommand) {
    case 'rename':
      if (name.isEmpty) {
        await context.reply(MessageBuilder(content: _usage));
        return;
      }
      await threads.update(
        thread.id,
        ThreadUpdateBuilder().name(name),
        auditLogReason: reason,
      );

    case 'archive':
      // Reply first: a message sent to an archived thread unarchives it
      // again.
      await context.reply(
        MessageBuilder(content: 'Archiving. Any new message reopens it.'),
      );
      await threads.update(
        thread.id,
        ThreadUpdateBuilder().archived(),
        auditLogReason: reason,
      );

    case 'lock':
      final locked = await threads.update(
        thread.id,
        ThreadUpdateBuilder().locked(!thread.isLocked),
        auditLogReason: reason,
      );
      await context.reply(
        MessageBuilder(
          content: locked.isLocked
              ? 'Locked. Only thread moderators can post here now.'
              : 'Unlocked.',
        ),
      );

    case 'members':
      final members = await threads.listMembers(thread.id, withMember: true);
      await context.reply(
        MessageBuilder(
          content:
              '${members.length} member(s): '
              '${members.map((m) => m.member?.displayName ?? '${m.userId}').join(', ')}',
        ),
      );
  }
}
