# Tusslepuffs

**An AI-native take on the .io genre with an on-chain economy backbone.**
Built for the [Crypto World's Fair Hackathon](https://www.colosseum.com/) on the [IPFPS](https://ipfps.org) platform.

🎮 **Live demo: https://tusslepuffs.chernovteam.dev**

![Tusslepuffs](docs/logo.png)

## What is it

Tusslepuffs is a browser-based 3D multiplayer game in the popular **.io genre**:
a near-zero learning curve — you eat, you grow, you brawl — on top of a
genuinely deep competitive stack. NPC boxers roam the island so the world is
alive even with few humans online.

We bet on technology, an AI-native approach, and we believe in blockchain:

- **Under the hood** — a powerful authoritative server: 3D physics in **Rust**
  (Rapier3D, 60 Hz) and battle-tested networking in **Go** (20 TPS game loop,
  binary protobuf over WebSocket).
- **Comfortable on bad internet** — the client runs the same physics engine
  compiled to **WASM** as a predictor, smoothing over network latency so the
  game stays responsive even on a weak connection.
- **On-chain economy** — not a bolt-on token: the game is a first-class tenant
  of the **IPFPS** platform — platform accounts, server-authoritative scoring,
  season leaderboards and crypto deposits (USDC/SOL) handled by the platform's
  double-entry ledger and escrow wallets.

## Vision: gameplay depth through LLMs

The .io formula gives instant fun; depth comes next. Our roadmap takes LLM
integration *inside* the game loop itself, not as a chatbot on the side:

- **Generative items** — LLM-generated objects and equipment for players,
  created on demand and validated server-side
- **Safe world modification** — players can ask the world to change (terrain,
  weather, events), with the authoritative server constraining every change so
  the game stays fair and deterministic
- **Persistent memory** — the world remembers: seasons, grudges and legends
  carried across sessions

## Key features

- **Server-authoritative multiplayer** — 20 TPS game loop, binary WebSocket protocol
- **Real physics** — Rapier3D simulated server-side (Rust, 60 Hz) *and* client-side
  for prediction (WASM), same forces both sides
- **Client-side prediction** — the browser runs the identical physics in WASM,
  masking latency for a smooth experience even on poor connections
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
