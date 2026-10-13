# Architecture

Tusslepuffs is a real-time multiplayer game with three main components:

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Go Backend** | Go | Game logic, WebSocket server, orchestration (20 TPS) |
| **Rapier Server** | Rust + Rapier3D | Physics simulation at 60 Hz |
| **Frontend** | TypeScript + Three.js | Rendering, client-side prediction |

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

## Protocol

All real-time traffic is **binary protobuf over a single WebSocket**
(client → server and server → client). The same `.proto` schemas drive the Go
server, the TypeScript client, and the documentation, so there is no
translation layer to drift out of sync.

## Go backend

The backend runs a fixed-tick game loop (default **20 TPS**, configurable).
Each tick, synchronous **systems** execute in priority order:

| Priority | System | Description |
|----------|--------|-------------|
| 1000 | PhysicsSystem | Position sync from the Rapier server |
| 950 | PlayerManagementSystem | Player lifecycle, mass queue |
| 900 | MovementSystem | Apply forces from player input |
| 25 | CollisionSystem | Food/player collision detection |
| 20 | FoodSystem | Perlin-noise-driven food spawning |
| 5 | MetricsSystem | Performance monitoring (TPS, snapshot lag) |

Asynchronous concerns (input validation, network broadcast, profiling) run as
event-driven **services** fed by an in-process event bus, so the tick loop
never blocks on I/O.

Configuration is fully env-driven (see `config.example.env`) with **no hidden
defaults for secrets** — the server refuses to start if a required credential
is missing.

## Rapier physics server

A standalone Rust service exposing Rapier3D over gRPC:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Timestep | 1/60 sec | Fixed physics step |
| Solver iterations | 8 | Stability (2x default) |
| CCD substeps | 4 | Prevent tunneling at punch speeds |
| Gravity | (0, -9.81, 0) | Earth-like |
| Max velocity | 2500 units/sec | Stability cap |

The same Rapier engine compiles to WASM for the browser, which runs
**client-side prediction** with the same force profiles as the server —
client and server physics agree by construction, not by constant syncing.

## Determinism & fairness

- Fixed tick rate; adrenaline/metabolism windows expire on server ticks
- Seeded PRNG (Mulberry32) for anything random that exists on both sides
- Server-authoritative scoring: kills and peak mass are computed server-side
  and written to the platform ledger — the client cannot forge results

## Scale validation

A built-in bot client (WebSocket + protobuf, same protocol as browsers) was
used for load testing; the stack was validated at 100+ concurrent players
with snapshot broadcasting enabled.
