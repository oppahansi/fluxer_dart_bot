# fluxer.dart-bot

An example bot for [fluxer.dart](https://github.com/oppahansi/fluxer.dart) —
deliberately modest. It exists to be read as a reference for how to build a
bot with the framework, not to be a feature-complete bot.

## What it does

- Logs in and prints a line when `READY` comes through.
- Logs every guild it can see (`lib/commands/guild_create_logger.dart`).
- Replies `pong` to a `!ping` message (`lib/commands/ping_command.dart`).

Each "command" is just a plain function in its own file under
`lib/commands/` — fluxer.dart doesn't have a formal command router yet, so
this is the pattern to follow until one lands.

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

## Part of the fluxer.dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_utils`](https://github.com/oppahansi/fluxer_utils) | generic building blocks |
| [`fluxer_core`](https://github.com/oppahansi/fluxer_core) | domain models |
| [`fluxer_rest`](https://github.com/oppahansi/fluxer_rest) | REST client |
| [`fluxer_gateway`](https://github.com/oppahansi/fluxer_gateway) | WebSocket gateway client |
| [`fluxer.dart`](https://github.com/oppahansi/fluxer.dart) | main framework — the `Bot` facade |
| [`fluxer.dart-bot`](https://github.com/oppahansi/fluxer.dart-bot) | *(this repo)* example bot |

## License

MIT — see [LICENSE](LICENSE).
