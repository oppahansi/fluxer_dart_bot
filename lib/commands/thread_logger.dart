import 'package:fluxer_dart/fluxer_dart.dart';

/// Logs thread activity.
///
/// Unlike `CHANNEL_UPDATE`, every thread event carries the whole thread,
/// so nothing here needs a REST fetch to describe what happened.
/// `THREAD_CREATE` doubles as "this bot was added to a thread", which
/// [ThreadCreateEvent.newlyCreated] tells apart from a new thread.
void registerThreadLoggers(Bot bot, Logger logger) {
  bot.onThreadCreate.listen((event) {
    final thread = event.thread;
    logger.info(
      event.newlyCreated
          ? 'Thread "${thread.name}" (${thread.id}) started in '
                '${thread.parentId}'
          : 'Joined thread "${thread.name}" (${thread.id})',
    );
  });

  bot.onThreadUpdate.listen((event) {
    final thread = event.thread;
    logger.info(
      'Thread "${thread.name}" (${thread.id}) updated: '
      '${thread.isArchived ? 'archived' : 'active'}'
      '${thread.isLocked ? ', locked' : ''}',
    );
  });

  bot.onThreadDelete.listen((event) {
    logger.info('Thread ${event.threadId} deleted from ${event.parentId}');
  });

  bot.onThreadMembersUpdate.listen((event) {
    logger.info(
      'Thread ${event.threadId}: +${event.addedMembers.length} '
      '-${event.removedMemberIds.length} member(s), now '
      '${event.memberCount}',
    );
  });
}
