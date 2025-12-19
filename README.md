## Hermes (macOS Zoom‑style demo app)

Native macOS video conferencing app built with **SwiftUI + LiveKit**, plus a small **Node.js (Fastify + TypeScript)** backend for guest auth and LiveKit token minting.

### What it demos
- **Guest join** (no accounts)
- **Multi‑user rooms** via LiveKit Cloud
- **Video + audio**
- **Chat** (LiveKit data messages)
- **Screen sharing** (ScreenCaptureKit; Screen Recording permission required)
- **Main stage**: screen share becomes the large stage view
- **Device selection**: camera / mic / speaker switching
- **Resilience**: reconnect UI + token refresh/rejoin
- **Keyboard shortcuts** + macOS window polish

### Repo layout
- **`client-macos/`**: SwiftUI macOS app
- **`backend/`**: Fastify API for guest auth + `/rooms/join` token issuing
- **`infra/`**: docker-compose for backend (optional)

### Quickstart (local dev)
#### 1) Backend env
Copy and fill:
- `backend/env.example` → `backend/.env`

Required:
- `HERMES_JWT_SIGNING_KEY`
- `LIVEKIT_URL`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`

You can also run:

```bash
bash scripts/bootstrap.sh
```

#### 2) Run backend

```bash
make backend-dev
```

Backend defaults to `http://127.0.0.1:3001`.

#### 3) Run the macOS app
Open and run in Xcode:

```bash
open client-macos/Hermes.xcodeproj
```

### Permissions (macOS)
Hermes requires:
- **Camera**
- **Microphone**
- **Screen Recording** (for listing windows/displays for screen share)

If screen sharing shows an error after you enable Screen Recording, **quit and relaunch Hermes**.

### Keyboard shortcuts
In the menu bar: **Meeting**
- **M**: mute/unmute
- **V**: start/stop video
- **⌘⇧S**: share screen
- **⌘,**: audio & video settings
- **⌘⇧C**: focus chat
- **⌘⇧P**: show participants
- **⌘\\**: toggle sidebar
- **⌘⇧L**: leave meeting

### Packaging (portfolio)
Creates an unsigned Release build and a distributable zip:

```bash
make package
```

Artifacts:
- `dist/Hermes.app`
- `dist/Hermes-macos.zip`

Note: builds are **unsigned** by default (intended for demo/portfolio use).
