# Changelog

## 0.2.0

- New commands demonstrating the capabilities added in the 0.2.0
  packages: `!pin` / `!unpin` / `!pins`, `!typing`, `!upload`,
  `!reactors`, `!clearreactions`, `!presence`, `!userinfo`,
  `!membersearch` and `!instance`.
- New standing listeners: `pins_update_logger.dart` re-lists a channel's
  pins when they change, since the event carries no message, and
  `moderation_logger.dart` wires up the bulk-delete, reaction-clearing,
  emoji, sticker, webhook, invite and audit-log streams.

## 0.1.0 — Initial release

Every command below was live-tested against a real self-hosted Fluxer
instance while it was built — see the README's "Fluxer version"
section.

- Messaging: `!ping`, `!embed`, `!reply`, `!react`, `!purge`.
- Guild/channel administration: `!channel`, `!slowmode`, `!permission`.
- Moderation: `!kick`, `!ban`/`!unban`, `!timeout`, `!role`,
  `!auditlog`, plus `requireGuildPermission` middleware gating all
  destructive commands.
- Emoji & stickers: `!emoji`, `!sticker` (gated on `createExpressions`,
  not `manageExpressions`).
- Webhooks: `!webhook create`/`delete`, demonstrating the separate
  token-based execute path alongside normal bot-token creation.
- Invites & info: `!invite`, `!serverinfo` (deliberately bypasses the
  gateway cache for accurate live counts).
- Reaction-based pagination: `!members`, `!help`, and the shared
  `sendPaginated()` helper.
- `!setup` — an owner-only, DM-based multi-turn setup flow, this
  platform's answer to Discord's ephemeral setup wizards (Fluxer has no
  ephemeral messages or interactions at all).
