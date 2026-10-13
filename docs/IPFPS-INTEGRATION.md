# IPFPS Platform Integration

Tusslepuffs runs as a tenant on the [IPFPS](https://ipfps.org) platform rather
than bolting tokens on afterwards. This document describes the integration at
the level judges need; tenant credentials are deliberately not part of this
repository.

## What the platform provides

- **Identity** — one platform account per human (username/password, email magic
  link, Solana wallet, Discord, Telegram mini-app). The same person gets an
  independent account inside every tenant they visit.
- **Balances** — double-entry ledger with a non-negative invariant, surfaced in
  tenant-defined currencies.
- **Crypto deposits** — escrow-wallet model for USDC / native SOL on Solana with
  per-tenant attribution; EVM/TON on the platform roadmap.
- **Seasons & XP** — per-tenant seasonal progression and global leaderboards.

## How the game composes with it

| Flow | Direction | Mechanism |
|------|-----------|-----------|
| Authentication | browser → game server | Platform session JWT (`Init-Data` header), validated by the game backend |
| Guest play | — | The game runs in guest mode without platform credentials; accounts unlock persistence |
| Score attribution | game → platform | Server-to-server API: kills and peak-mass flushes are written from the authoritative game loop, not the client |
| Leaderboard | platform → browser | The game exposes a read-through `GET /api/leaderboard` (season + all-time) backed by platform standings |
| Deposits | browser ↔ platform | Handled entirely by the platform escrow flow; the game only reads balances |

## Server-side scoring (anti-cheat by construction)

Scoring rules are fixed server-side and env-tunable:

- each attributed kill: `IPFPS_KILL_SCORE` points
- on death, peak mass contributes `peak_mass / IPFPS_MASS_SCORE_DIVISOR`
- scores are flushed to the platform through the tenant S2S API with a
  per-request timeout; the game server refuses to start when the integration
  is enabled but credentials are missing — there are no fallback credentials

Because physics, combat resolution and scoring all live in the authoritative
backend, a modified client cannot inflate its standing — the same property
that makes the multiplayer fair makes the on-chain scores trustworthy.

## Tenant configuration

```
IPFPS_ENABLED=true
IPFPS_ENDPOINT=https://<tenant>.ipfps.org
IPFPS_KEY_ID=<issued at onboarding>
IPFPS_SECRET=<issued at onboarding, shown once>
IPFPS_SEASON=cwfair
```

See `config.example.env` for the full set of tuning knobs (scoring weights,
timeouts, season slice).
