# fluxer_dart_bot

An example bot for [fluxer_dart](https://github.com/oppahansi/fluxer_dart) —
deliberately modest. It exists to be read as a reference for how to build a
bot with the framework, not to be a feature-complete bot.

## What it does

- Logs in — connection lifecycle (`Connecting`/`Identifying`/`Connected`/
  `READY`/...) is printed automatically by `fluxer_dart_gateway` itself once you
  give `Bot` a real `Logger`, not something this example prints manually.
- Logs every guild it can see (`lib/commands/guild_create_logger.dart`) —
  a plain `bot.onGuildCreate.listen(...)` handler, not a command.
- Replies `pong` to `!ping`, rate-limited to once per 5 seconds per user
  (`lib/commands/ping_command.dart`), registered on a `CommandRouter` in
  `bin/bot.dart` — demonstrates fluent command registration and
  middleware (`cooldown(...)`).

### Logging and handler safety

`bin/bot.dart` passes a `PrintLogger` into `Bot`, which is what makes the
gateway's own lifecycle logging (INFO for connect/resume, DEBUG for every
dispatch, WARNING/ERROR for reconnects and fatal closes) show up at all —
the default is a silent `NoopLogger`.

`main()`'s whole body runs inside `runGuarded(...)` (from `fluxer_dart_utils`),
which wraps `dart:async`'s `runZonedGuarded` — it catches any otherwise-
uncaught asynchronous error and routes it through the logger instead of
crashing the process, including exceptions thrown inside the plain
`bot.onXyz.listen(...)` callbacks below. Event handlers don't need a
special method to be safe; the `Zone` established once at the top
protects everything that runs within it.

## Setup

1. Get a bot token. Against your own self-hosted instance: register an
   account, create an OAuth2 application (`POST /oauth2/applications`),
   and read the token off the `bot.token` field in the response — see
   [the operator docs](https://docs.fluxer.app/operator/get-started/) for
   running an instance in the first place.
2. Copy `.env.example` to `.env` and fill in `FLUXER_BOT_TOKEN`. If you're
   pointing at a self-hosted instance rather than production
   `api.fluxer.app`, also set `FLUXER_REST_BASE_URL`.
3. Invite the bot to a guild (OAuth2 `scope=bot` authorize flow).
4. Run it:

   ```sh
   dart pub get
   dart run bin/bot.dart
   ```

## Part of the fluxer_dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_dart_utils`](https://github.com/oppahansi/fluxer_dart_utils) | generic building blocks |
| [`fluxer_dart_core`](https://github.com/oppahansi/fluxer_dart_core) | domain models |
| [`fluxer_dart_rest`](https://github.com/oppahansi/fluxer_dart_rest) | REST client |
| [`fluxer_dart_gateway`](https://github.com/oppahansi/fluxer_dart_gateway) | WebSocket gateway client |
| [`fluxer_dart_voice`](https://github.com/oppahansi/fluxer_dart_voice) | voice support |
| [`fluxer_dart`](https://github.com/oppahansi/fluxer_dart) | main framework — the `Bot` facade |
| [`fluxer_dart_bot`](https://github.com/oppahansi/fluxer_dart_bot) | *(this repo)* example bot |

## License

MIT — see [LICENSE](LICENSE).
