# ZappShare

Peer-to-peer file sharing across devices using WebRTC data channels. No cloud upload — files transfer directly between browsers and native apps over an encrypted connection.

Built with Flutter (iOS, Android, macOS, Windows, Linux, Web) and a lightweight Dart signaling server.

## How it works

```
┌──────────┐         WebSocket          ┌─────────────────┐
│  Device A ├──────────────────────────►│ Signaling Server │
└─────┬────┘   (offer/answer/ICE)       └────────┬────────┘
      │                                          │
      │         WebRTC DataChannel               │
      │◄────────────────────────────────────────►│
      │         (direct, encrypted)              │
┌─────┴────┐                             ┌───────┴───────┐
│  Device B ├─────────────────────────►  │ TURN Relay     │
└──────────┘                             │ (fallback only)│
                                         └───────────────┘
```

1. Both devices connect to the signaling server over WebSocket
2. The server brokers the WebRTC handshake (SDP offer/answer + ICE candidates)
3. A direct peer-to-peer data channel is established for file transfer
4. If direct connectivity fails (symmetric NAT, firewalls), traffic relays through a TURN server

All file data is end-to-end encrypted via DTLS-SRTP. The signaling server never sees file contents.

## Quick start

```bash
# Terminal 1 — signaling server
cd signaling_server && dart pub get && dart run bin/server.dart

# Terminal 2 — Flutter app
flutter pub get && flutter run
```

The app connects to `ws://localhost:8080` in debug mode automatically.

## Project structure

```
lib/
├── core/
│   ├── config/       # App-wide configuration (signaling URL, ICE servers)
│   ├── provider/     # WebRTC provider (connection state, file transfer)
│   ├── colors/       # Theme colors
│   ├── router/       # Go Router setup
│   └── username/     # Random display name generation
├── screens/          # Home screen (pairing UI, file picker, transfer progress)
├── widgets/          # QR code dialogs, file picker (platform-conditional)
└── utils/            # File saving (native + web), platform helpers

signaling_server/
├── bin/server.dart   # WebSocket signaling server with TURN provisioning
├── Dockerfile        # Multi-stage build for production
└── fly.toml          # Fly.io deployment config
```

## Configuration

### Signaling server URL

Resolved automatically by build mode:

| Mode    | URL                                    |
|---------|----------------------------------------|
| Debug   | `ws://localhost:8080`                  |
| Release | `wss://zappshare-signaling.fly.dev`    |

Override at compile time:

```bash
flutter run --dart-define=SIGNALING_URL=wss://your-server.example.com
```

### TURN relay (required for production)

Without TURN, ~15–20% of connections will fail — especially on mobile networks and behind corporate firewalls. The signaling server provisions ICE credentials to clients automatically via environment variables.

| Variable          | Description                                              |
|-------------------|----------------------------------------------------------|
| `TURN_URLS`       | Comma-separated TURN/TURNS URLs                          |
| `TURN_SECRET`     | HMAC shared secret (for coturn `use-auth-secret` mode)   |
| `TURN_USERNAME`   | Static username (for managed services)                   |
| `TURN_CREDENTIAL` | Static credential (for managed services)                 |

Set **either** `TURN_SECRET` (generates 24h HMAC-SHA1 credentials) **or** `TURN_USERNAME` + `TURN_CREDENTIAL` (static pass-through). Not both.

**Example — coturn with HMAC credentials:**

```bash
fly secrets set \
  TURN_URLS="turn:turn.example.com:3478,turns:turn.example.com:5349" \
  TURN_SECRET="your-coturn-static-auth-secret"
```

**Example — managed service (Metered, Xirsys, Twilio):**

```bash
fly secrets set \
  TURN_URLS="turn:global.turn.twilio.com:3478,turns:global.turn.twilio.com:443" \
  TURN_USERNAME="your-username" \
  TURN_CREDENTIAL="your-credential"
```

**Local development with TURN (optional):**

```bash
TURN_URLS="turn:turn.example.com:3478" TURN_SECRET="mysecret" dart run bin/server.dart
```

If no TURN variables are set, only public Google STUN servers are provided.

## Deployment

### Signaling server → Fly.io

```bash
# One-time setup
brew install flyctl          # or: curl -L https://fly.io/install.sh | sh
fly auth login
cd signaling_server
fly launch                   # accept defaults, skip database provisioning

# Deploy (and subsequent deploys)
fly deploy
```

The server will be live at `wss://zappshare-signaling.fly.dev`.

**Custom domain:**

```bash
fly certs add signal.yourdomain.com
# Then add a CNAME: signal.yourdomain.com → zappshare-signaling.fly.dev
```

### Flutter app

```bash
# Android / iOS
flutter build apk --release
flutter build ios --release

# Web (deploy to Firebase Hosting, Vercel, etc.)
flutter build web --release

# macOS / Windows / Linux
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## Tech stack

| Layer            | Technology                              |
|------------------|-----------------------------------------|
| UI               | Flutter + Material 3, ScreenUtil        |
| State management | Provider (ChangeNotifier)               |
| Networking       | WebRTC (flutter_webrtc), WebSocket      |
| Signaling        | Dart HttpServer + WebSocket             |
| Hosting          | Fly.io (signaling), Firebase (web app)  |
| File I/O         | path_provider (native), web download API|
