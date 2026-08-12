import 'dart:math';

import 'package:fluxer_dart/fluxer_dart.dart';

import 'paginator.dart';

const _pageSize = 8;

/// `!help` — pages through every command currently registered on
/// [router], read via [CommandRouter.commandNames] rather than a
/// hand-maintained list that could drift out of sync with `bin/bot.dart`.
CommandHandler helpCommand(CommandRouter router) {
  return (context) async {
    final names = router.commandNames;
    final totalPages = (names.length / _pageSize).ceil();

    String renderPage(int page) {
      final start = page * _pageSize;
      final end = min(start + _pageSize, names.length);
      final lines = names.sublist(start, end).map((n) => '- `!$n`').join('\n');
      return 'Commands (page ${page + 1}/$totalPages):\n$lines';
    }

    await sendPaginated(context, totalPages: totalPages, render: renderPage);
  };
}
