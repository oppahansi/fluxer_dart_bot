# fluxer_dart_bot

An example bot for [fluxer_dart](https://github.com/oppahansi/fluxer_dart) —
deliberately modest in structure (`bin/bot.dart` + one file per command
under `lib/commands/`), but it now walks through effectively everything a
Fluxer bot can actually do. It exists to be read as a reference for how to
build a bot with the framework and by example of what the platform itself
supports, not to be a "useful" bot on its own.

Every command below was verified against a real self-hosted Fluxer
instance while it was built, not just unit-tested against mocks — see
each package's own commit history for the bugs that live testing caught
along the way (wrong default permission flags, gaps between the
gateway's cached data and REST, a server-side pagination default that
silently truncated results).

## Commands

Connects, logs `READY`, and logs every guild it can see
(`lib/commands/guild_create_logger.dart`, a plain
`bot.onGuildCreate.listen(...)` handler, not a command) automatically —
nothing below is needed just to bring the bot online.

| Command | What it demonstrates | Guild permission required |
|---|---|---|
| `!ping` | Basic command registration + `cooldown(...)` middleware (5s per user) | — |
| `!embed` | `EmbedBuilder`, rich message content | — |
| `!reply` | `MessageBuilder.replyTo()` — a real reply reference, not just same-channel | — |
| `!react` | `MessageRestManager.addReaction()` | — |
| `!purge <1-100>` | Listing + `bulkDelete()` | `manageMessages` |
| `!channel create\|rename\|delete` | Channel CRUD, `ChannelCreateBuilder`/`ChannelUpdateBuilder` | `manageChannels` |
| `!slowmode <seconds>` | Per-channel rate limiting | `manageChannels` |
| `!permission set\|clear <role_id> <flag>` | Role-scoped channel permission overwrites | `manageRoles` |
| `!kick` | Member removal | `kickMembers` |
| `!ban [reason]` / `!unban` | Ban management | `banMembers` |
| `!timeout <minutes> [reason]` | Member timeout (`0` clears it) | `moderateMembers` |
| `!role create\|delete\|add\|remove` | Guild role CRUD + member role assignment | `manageRoles` |
| `!auditlog [count]` | `GuildRestManager.getAuditLogs()` | `viewAuditLog` |
| `!emoji add\|clone\|delete` | Custom emoji management, data-URI image upload | `createExpressions` |
| `!sticker add\|clone\|delete` | Custom sticker management | `createExpressions` |
| `!webhook create <name>` / `!webhook delete <id>` | Webhook creation **and** the separate token-based execute path (`WebhookExecuteClient`, no bot auth at all) | `manageWebhooks` |
| `!invite create` / `!invite delete <code>` | Channel invite management | `createInstantInvite` |
| `!serverinfo` | Guild stats fetched fresh via REST (deliberately bypasses the gateway cache — see the doc comment on `handleServerInfo`) | — |
| `!members` | Reaction-based pagination over the full member list | — |
| `!help` | Reaction-based pagination over `CommandRouter.commandNames` | — |

A standing (non-command) listener also logs every reaction added anywhere
the bot can see (`lib/commands/reaction_add_logger.dart`), demonstrating
`bot.onMessageReactionAdd` outside of the pagination use case.

### The reaction-based paginator

`lib/commands/paginator.dart`'s `sendPaginated()` — attaches ◀️/▶️ to a
sent message, listens on `bot.onMessageReactionAdd` filtered to that
message, edits it in place per page, and removes the clicking user's
reaction so they can click again. Used by `!members` and `!help`.
Deliberately simple: a fixed idle timeout cancels the listener, and
nothing persists across a bot restart — a real pagination system would
need to survive both.

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

## Where this is limited compared to a Discord bot

Fluxer's architecture is close enough to Discord's that most of this
reads as familiar — but it isn't Discord, and some gaps below are the
*platform's*, not this bot's or the framework's. Verified against
Fluxer's own OpenAPI spec and live instance, not assumed from Discord
parity.

- **No slash commands / interactions at all.** Confirmed against the
  live OpenAPI spec: there's no `/interactions` or `/commands` path,
  anywhere. No buttons, select menus, modals, or autocomplete either —
  those are all built on Discord's interactions system, which Fluxer
  doesn't have. Every command here is message-content based (`!name
  args`), which is the *only* command style available on this platform,
  not a stylistic choice this bot made.
- **No voice.** `fluxer_dart_voice` exists as a scaffold-only sibling
  repo (LiveKit-based, per the ecosystem's main roadmap) but isn't
  implemented — this bot can see voice channels (`GuildVoiceChannel` in
  `fluxer_dart_core`) but can't join one, play audio, or read voice
  state.
- **No file/attachment uploads.** Incoming attachments decode fine
  (`Attachment` in `fluxer_dart_core`), but *sending* one needs Fluxer's
  presigned-upload flow, which no command here (or `MessageBuilder`/
  `WebhookExecuteClient` in `fluxer_dart_rest`) implements. Emoji/sticker
  images are the one exception — those go through a plain base64 data
  URI, not the presigned flow, per the OpenAPI spec's own
  `image` field.
- **No DMs.** There's no `createDm`-equivalent anywhere in
  `fluxer_dart_rest` yet, so this bot can only talk in guild channels it's
  been invited into.
- **Permission checks are guild-level only.** `requireGuildPermission`
  (in `fluxer_dart`) resolves a member's roles and computes effective
  guild permissions, but it's blind to per-channel permission
  overwrites — a command gated on `manageChannels` will let a member
  through even if that channel's overwrites specifically deny them,
  same as Discord's `MANAGE_CHANNELS` at the guild level would, just
  without Discord's own channel-overwrite resolution step layered on
  top. Documented as a known gap since BM3, not silently wrong.
- **No threads or forum channels modeled.** `Channel`'s sealed hierarchy
  in `fluxer_dart_core` covers text/voice/category/DM/group-DM — anything
  else (including any thread-like channel type Fluxer might add) decodes
  as `UnknownChannel` rather than crashing, but this bot has no
  thread-aware commands.
- **No presence/typing-indicator-driven behavior.** `onTypingStart` is
  wired at the SDK level, but nothing here reacts to it, and there's no
  presence (`online`/`idle`/`dnd`) event stream at all yet — `!serverinfo`
  only gets an aggregate `online_count`, not per-member presence.
- **Pagination doesn't survive a restart.** `sendPaginated()`'s reaction
  listeners are in-memory and time out after a fixed idle window; a
  paginated `!members`/`!help` message stops responding to clicks once
  the bot restarts, with no attempt to resume it.
- **Sharding is supported by the SDK but not exercised here.** `Bot`
  always routes through `GatewayShardManager` and will split across
  shards correctly for a large bot, but this example only ever runs
  against a single-shard self-hosted test guild — nothing here
  specifically demonstrates multi-shard behavior beyond what `fluxer_dart`
  itself already tests.

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
