# Changelog

## 0.2.0 — 2026-08-12

### Added

Every command below was live-tested against a real self-hosted Fluxer
instance while it was built — see the README's "Fluxer version"
section.

- Messaging: `!ping`, `!embed`, `!reply`, `!react`, `!purge`.
- Guild/channel administration: `!channel`, `!slowmode`, `!permission`.
- Moderation: `!kick`, `!ban`/`!unban`, `!timeout`, `!role`,
  `!auditlog`, plus `requireGuildPermission` middleware gating all
  destructive commands.
- Emoji & stickers: `!emoji`, `!sticker` (gated on `createExpressions`,
  not `manageExpressions` — a real permission-flag correction found by
  live testing).
- Webhooks: `!webhook create`/`delete`, demonstrating the separate
  token-based execute path alongside normal bot-token creation.
- Invites & info: `!invite`, `!serverinfo` (deliberately bypasses the
  gateway cache for accurate live counts).
- Reaction-based pagination: `!members`, `!help`, and the shared
  `sendPaginated()` helper.
- `!setup` — an owner-only, DM-based multi-turn setup flow, this
  platform's answer to Discord's ephemeral setup wizards (Fluxer has no
  ephemeral messages or interactions at all).

### Fixed

- `!members` previously showed only 1 member on any guild — traced to
  `GuildMemberRestManager.list()` in `fluxer_dart_rest` never sending an
  explicit `limit`, which Fluxer defaults to 1.

## 0.1.0

Initial scaffolding plus `!ping` — connects, logs `READY`, replies
`pong`.
