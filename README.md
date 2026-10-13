# Tusslepuffs

**A real-time multiplayer island brawler with an on-chain economy backbone.**
Built for the [Crypto World's Fair Hackathon](https://www.colosseum.com/) on the [IPFPS](https://ipfps.org) platform.

🎮 **Live demo: https://tusslepuffs.chernovteam.dev**

![Tusslepuffs](docs/logo.png)

## What is it

Tusslepuffs is a browser-based 3D multiplayer arena game: grow your puff by eating,
fight with momentum-based punches, hunt down smaller players — or run for your life.
NPC boxers roam the island so the world is alive even with few humans online.

The crypto angle is not a bolt-on token: the game is integrated into the **IPFPS**
platform as a first-class tenant — platform accounts, server-authoritative scoring,
season leaderboards and crypto deposits (USDC/SOL) handled by the platform's
double-entry ledger and escrow wallets.

## Key features

- **Server-authoritative multiplayer** — 20 TPS game loop, binary WebSocket protocol
- **Real physics** — Rapier3D simulated server-side (Rust, 60 Hz) *and* client-side
  for prediction (WASM), same forces both sides
- **Metabolism model** — mass is energy: movement and punches cost mass proportional
  to `(mass/100)^1.3`, so turtling loses and hunting wins
- **Devour mechanic** — genre finisher: attacker 3x heavier grabs the victim
  (GRAB → HOLD → GULP), victim can counter or escape during wind-up
- **Adrenaline escape** — taking damage grants a short boost window (prey counterplay)
- **Coin glasses (sponsor mechanic)** — food fills a coin's glass; a full glass bursts
  into mass and grows capacity
- **Platform integration (IPFPS)** — one identity across tenants, season XP, global
  leaderboard, crypto top-ups via platform escrow
- **Bots & load testing** — built-in bot client used to validate 100+ concurrent players

## Architecture

Three components, two languages, one deterministic game:

```
┌─────────────┐      WebSocket (Binary Protobuf)      ┌─────────────┐
│   Browser   │ ◄──────────────────────────────────►  │  Go Server  │
│  (Three.js) │                                       │   (20 TPS)  │
└─────────────┘                                       └──────┬──────┘
       │                                                     │
       │ Rapier WASM                                         │ gRPC
       │ (client prediction)                                 │
       ▼                                                     ▼
┌─────────────┐                                       ┌─────────────┐
│ Rapier WASM │                                       │Rapier Server│
│  (browser)  │                                       │ (60 Hz Rust)│
└─────────────┘                                       └─────────────┘
```

| Component | Tech | Role |
|-----------|------|------|
| Go backend | Go 1.24 | Game orchestration, WebSocket, IPFPS integration, static file serving |
| Physics server | Rust + Rapier3D | Deterministic physics at 60 Hz via gRPC |
| Frontend | TypeScript + Three.js | Rendering, client-side prediction, VFX |

Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
Platform integration: [docs/IPFPS-INTEGRATION.md](docs/IPFPS-INTEGRATION.md)

## Reproducibility

The primary way to evaluate the project is the **live demo** above. For
transparency, pre-built Linux `amd64` binaries are attached to
[GitHub Releases](../../releases) — the exact artifacts running on the demo
server (Go backend, Rapier physics, built frontend). If you want to verify the
demo runs the published build, you can self-host it:

```bash
# 1. Download and unpack the latest release
curl -sL https://github.com/vizzyolog/tusslepuffs-cwfair/releases/latest/download/x-cells_linux_amd64.tar.gz | tar xz
cd x-cells

# 2. Review and adjust configuration
cp config.example.env config.env
$EDITOR config.env

# 3. Install (needs root for systemd units)
sudo ./install.sh

# 4. Play
xdg-open http://localhost:8181
```

Without systemd you can run the two processes directly:

```bash
./rapier-server &          # physics, gRPC on :50052, health on :50053
./server                   # game server on :8180 (set SERVER_PORT)
```

The server runs in guest mode out of the box. To connect it to the IPFPS
platform, fill in the `IPFPS_*` variables in `config.env` (tenant credentials are
issued at platform onboarding — see [docs/IPFPS-INTEGRATION.md](docs/IPFPS-INTEGRATION.md)).

## Source code

This repository ships runnable binaries. The full source (Go backend, Rust physics
server, TypeScript client, protocol definitions, load-testing harness) is available
to hackathon judges and organizers on request — contact the team via the submission.

## License

All rights reserved. The binaries are provided for evaluation and demonstration
purposes as part of the Crypto World's Fair Hackathon submission.
