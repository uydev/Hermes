# Hermes

**Hermes** is a native macOS video conferencing application that provides real-time audio/video communication, screen sharing, and chat capabilities. Built with modern SwiftUI and leveraging LiveKit's WebRTC infrastructure, Hermes delivers a Zoom/Teams-like experience with a focus on simplicity, performance, and privacy.

---

## Introduction

Hermes is a full-stack video conferencing solution designed for macOS, enabling users to join meetings as guests without requiring accounts or complex authentication. The application demonstrates enterprise-grade real-time communication capabilities while maintaining a lightweight, user-friendly interface.

The project consists of three main components:
- **macOS Client**: Native SwiftUI application providing the user interface and media handling
- **Backend API**: Node.js/Fastify service for authentication and token management
- **Infrastructure**: AWS EC2 deployment with Terraform automation

---

## Full Depth Functionality

### Core Features

#### 1. **Guest Authentication**
- No user accounts required
- Simple display name and room name entry
- JWT-based session management with secure token storage in macOS Keychain
- Automatic session persistence across app restarts

#### 2. **Real-Time Video Conferencing**
- Multi-participant video calls with adaptive quality
- Camera on/off toggle with blank placeholder when disabled (no frozen frames)
- Participant tiles with speaking indicators
- Main stage view that automatically promotes screen shares
- Responsive grid layout adapting to participant count

#### 3. **Audio Communication**
- High-quality audio transmission via WebRTC
- Microphone mute/unmute controls
- Real-time audio device selection (microphones and speakers)
- Speaking detection with visual indicators

#### 4. **Screen Sharing**
- Native macOS ScreenCaptureKit integration
- Window and display selection interface
- Screen share automatically becomes main stage view
- Seamless switching between video and screen share

#### 5. **Chat System**
- Real-time text messaging via LiveKit data channels
- Message history persistence during session
- Chat sidebar with auto-scroll to latest messages
- Keyboard shortcuts for quick access

#### 6. **Device Management**
- Dynamic camera device enumeration and switching
- Microphone device selection
- Speaker/audio output device selection
- Real-time device availability updates

#### 7. **Connection Resilience**
- Automatic reconnection on network interruptions
- Token refresh and rejoin logic
- Connection state indicators (connecting, connected, reconnecting, disconnected)
- Error handling with user-friendly messages

#### 8. **User Experience**
- Native macOS design language with SwiftUI
- Keyboard shortcuts for all major actions
- Custom "About" window with app branding
- Window management and state persistence
- Permission handling for camera, microphone, and screen recording

---

## Tech Stack

### Client (macOS)
- **SwiftUI**: Modern declarative UI framework
- **AppKit**: Integration with macOS system services
- **LiveKit Swift SDK**: WebRTC-based real-time communication
- **AVFoundation**: Audio/video capture and playback
- **ScreenCaptureKit**: Native macOS screen sharing API
- **Combine**: Reactive programming for state management
- **Security Framework**: Keychain integration for secure token storage

### Backend
- **Node.js**: JavaScript runtime
- **Fastify**: High-performance web framework
- **TypeScript**: Type-safe JavaScript development
- **JSON Web Tokens (JWT)**: Secure token-based authentication
- **Zod**: Runtime type validation and schema validation
- **dotenv**: Environment variable management

### Infrastructure & DevOps
- **Terraform**: Infrastructure as Code (IaC) for AWS provisioning
- **AWS EC2**: Virtual server hosting
- **AWS Security Groups**: Network firewall configuration
- **AWS Elastic IP**: Static public IP address
- **Docker**: Containerization for backend deployment
- **Nginx**: Reverse proxy and HTTP server
- **Certbot**: SSL/TLS certificate management (Let's Encrypt)

### Third-Party Services
- **LiveKit Cloud**: Managed WebRTC infrastructure for media routing
  - Handles STUN/TURN servers for NAT traversal
  - Media server for multi-party communication
  - Data channels for chat functionality
  - Token-based access control

---

## Programming & Scripting Languages

### Primary Languages
- **Swift**: macOS client application (26 Swift files)
- **TypeScript**: Backend API server
- **JavaScript**: Backend tests and build scripts

### Configuration & Infrastructure
- **HCL (HashiCorp Configuration Language)**: Terraform infrastructure definitions
- **Bash/Shell**: Deployment scripts, EC2 user-data automation
- **XML/PLIST**: macOS Info.plist configuration
- **JSON**: Package manifests, configuration files

---

## Persistent Storage & Databases

### Client-Side Storage
- **macOS Keychain**: Secure storage of JWT tokens using `KeychainStore` wrapper
  - Service: `com.hephaestus-systems.hermes`
  - Account: `hermes.guest.jwt`
  - Encrypted at OS level, accessible only to the Hermes application

### Backend Storage
- **No persistent database**: Stateless backend design
- **In-memory session management**: JWT tokens contain all necessary session data
- **Environment variables**: Configuration stored in `.env` file (not committed)

### Rationale
Hermes uses a stateless architecture where all session information is encoded in JWT tokens. This eliminates the need for a database, simplifies deployment, and improves scalability. The backend only validates tokens and issues new LiveKit tokens—no user data persistence is required.

---

## Cloud Storage & Infrastructure

### AWS Services Used
- **EC2 (t3.micro)**: Ubuntu 22.04 LTS instance hosting the backend
- **Elastic IP**: Static public IP address (`15.188.222.229` in production)
- **Security Groups**: Firewall rules allowing:
  - Port 443 (HTTPS) from anywhere
  - Port 22 (SSH) from anywhere (should be restricted in production)
  - Port 80 (HTTP) handled by Nginx
- **VPC**: Default VPC in `eu-west-3` (Paris) region

### Deployment Architecture
```
Internet → AWS Elastic IP → EC2 Instance
                          ├─ Nginx (Port 80/443)
                          └─ Docker Container (Port 3001)
                              └─ Node.js Backend
```

### Infrastructure Automation
- **Terraform**: Provisions EC2, security groups, Elastic IP
- **User-data script**: Automates Nginx installation and configuration on instance boot
- **Docker**: Containerizes backend for consistent deployment
- **Nginx reverse proxy**: Routes HTTP traffic to backend container

---

## Third-Party Dependencies

### Critical External Services
1. **LiveKit Cloud** (`wss://*.livekit.cloud`)
   - WebRTC media server
   - STUN/TURN servers for NAT traversal
   - Real-time data channels for chat
   - Token-based authentication

### npm Packages (Backend)
- `fastify@^5.6.2`: Web framework
- `@fastify/cors@^11.2.0`: CORS middleware
- `jsonwebtoken@^9.0.3`: JWT signing/verification
- `zod@^4.2.1`: Schema validation
- `dotenv@^17.2.3`: Environment variable loading

### Swift Packages (Client)
- `LiveKit`: Official LiveKit Swift SDK (via Swift Package Manager)

---

## Development Areas

### Frontend (macOS Client)
- **Views**: SwiftUI views for UI components
  - `JoinView`: Initial room entry interface
  - `MeetingShellView`: Main meeting interface with video grid
  - `ParticipantTileView`: Individual participant video tile
  - `ScreenSharePickerView`: Screen/window selection UI
  - `DeviceSettingsView`: Audio/video device configuration
  - `AboutHermesView`: Custom about window

- **Services**: Business logic and state management
  - `LiveKitMeetingViewModel`: Core meeting state and LiveKit integration
  - `MeetingStore`: Meeting session state
  - `SessionStore`: User session persistence
  - `BackendClient`: HTTP API client for backend communication
  - `KeychainStore`: Secure token storage wrapper

- **LiveKit Integration**: WebRTC abstraction layer
  - `LiveKitVideoView`: NSView wrapper for video rendering
  - `LiveKitMeetingViewModel`: Room delegate and state management
  - `ParticipantModels`: Data models for participants and tiles
  - `ChatModels`: Chat message data structures

### Backend API
- **Routes**:
  - `POST /auth/guest`: Guest authentication endpoint
  - `POST /rooms/join`: LiveKit token issuance endpoint
  - `GET /health`: Health check endpoint

- **Authentication**:
  - `hermesAuth.ts`: JWT signing and verification logic
  - Custom claims: `sub`, `displayName`, `room`, `role`
  - Token expiration: 60 minutes default

- **Validation**:
  - Zod schemas for request validation
  - Type-safe request/response handling

### Infrastructure
- **Terraform Modules**:
  - EC2 instance configuration
  - Security group rules
  - Elastic IP allocation
  - VPC and subnet discovery

- **Deployment Scripts**:
  - `deploy-backend.sh`: Docker image build and deployment
  - `user-data.sh`: EC2 bootstrap script for Nginx setup

---

## Security

### Authentication & Authorization
- **JWT-based authentication**: Two-tier token system
  1. Hermes JWT: Issued by backend, contains user identity and room info
  2. LiveKit JWT: Issued by backend using LiveKit API secret, grants room access

- **Token Security**:
  - HS256 algorithm for signing
  - Minimum 16-character signing key requirement
  - Token expiration (60 minutes)
  - Issuer and audience validation
  - Secure storage in macOS Keychain

### Network Security
- **HTTPS/TLS**: Production deployment uses HTTPS (via Nginx + Let's Encrypt)
- **App Transport Security (ATS)**: macOS enforces HTTPS by default
  - Exception configured for development/testing (HTTP allowed for specific IP)
  - Should be removed in production when HTTPS is fully configured

### Data Privacy
- **No persistent user data**: No database means no user information stored
- **Stateless backend**: Each request is independent, no session state
- **Keychain encryption**: Tokens encrypted at OS level
- **WebRTC encryption**: DTLS/SRTP encryption for media streams (built into WebRTC)

### Infrastructure Security
- **Security Groups**: Firewall rules restricting access
- **SSH Key Authentication**: EC2 access via SSH key pairs
- **Environment Variables**: Sensitive credentials stored in `.env` (not committed)
- **Docker Isolation**: Backend runs in isolated container

### Security Considerations
- SSH port (22) currently open to `0.0.0.0/0` — should be restricted to specific IPs in production
- HTTP allowed via ATS exception — should be removed when HTTPS is fully configured
- JWT signing key must be strong (minimum 16 characters enforced)

---

## Implementation Notes

### Architecture Patterns

#### Client-Side
- **MVVM (Model-View-ViewModel)**: SwiftUI views observe `@Published` properties
- **Reactive Programming**: Combine framework for state updates
- **Delegate Pattern**: LiveKit room delegate for event handling
- **Singleton Services**: `MeetingStore`, `SessionStore` as shared state

#### Backend
- **Stateless API**: No server-side session storage
- **Plugin Architecture**: Fastify plugins for route organization
- **Middleware Pattern**: CORS, request validation
- **Error Handling**: Structured error responses with status codes

### Key Implementation Details

#### Video Rendering
- Uses LiveKit's `VideoView` (AppKit) wrapped in `NSViewRepresentable` for SwiftUI
- Video tracks are managed by LiveKit SDK, SwiftUI observes track availability
- Camera disabled state shows blank placeholder instead of frozen frame

#### Screen Sharing
- Native `ScreenCaptureKit` API for macOS 12.3+
- Requires Screen Recording permission
- Window and display enumeration for user selection
- Screen share track published as separate LiveKit video track

#### Token Flow
```
1. User enters name/room → POST /auth/guest
2. Backend issues Hermes JWT → Stored in Keychain
3. User joins meeting → POST /rooms/join (with Hermes JWT)
4. Backend validates JWT → Issues LiveKit JWT
5. Client connects to LiveKit → Uses LiveKit JWT
```

#### Reconnection Logic
- Detects token expiration errors
- Automatically requests new LiveKit token from backend
- Reconnects to LiveKit room with fresh token
- Preserves media state (camera/mic on/off)

### Configuration Management
- **Backend URL**: Configurable via `Info.plist` key `BackendURL`
- **Environment Variables**: Backend uses `.env` file
- **Terraform Variables**: Infrastructure configuration via `variables.tf`

---

## Challenging Parts During Development

### 1. **macOS App Transport Security (ATS)**
**Challenge**: macOS blocks HTTP connections by default, requiring HTTPS or explicit exceptions.

**Solution**: Added ATS exception in `Info.plist` for development/testing. For production, configured Nginx with Let's Encrypt SSL certificates.

**Lesson**: macOS security policies are strict—plan for HTTPS from the start.

### 2. **Circular Dependency in Terraform**
**Challenge**: EC2 instance `user_data` needed Elastic IP address, but EIP depends on instance ID, creating a circular dependency.

**Solution**: Used Terraform template variables with conditional logic. Set Nginx `server_name` to `_` (wildcard) during instance creation, which accepts any hostname/IP. This decouples instance creation from EIP assignment.

**Lesson**: Infrastructure dependencies require careful planning; sometimes you need to accept less-than-ideal initial states.

### 3. **Video Track State Management**
**Challenge**: When camera is disabled, LiveKit may still provide a video track showing the last frame (frozen image), which looks unprofessional.

**Solution**: Added `isCameraEnabled` check in `ParticipantTileView`. When camera is disabled, hide the video track entirely and show a blank placeholder with participant name.

**Lesson**: SDK behavior doesn't always match UX expectations—you need to add application-level logic.

### 4. **Screen Recording Permission**
**Challenge**: ScreenCaptureKit requires Screen Recording permission, but the app doesn't automatically prompt—users must enable it manually in System Settings.

**Solution**: Added clear error messages directing users to System Settings. Implemented permission check via `AVCaptureDevice.authorizationStatus`.

**Lesson**: macOS permissions are complex; always provide clear user guidance.

### 5. **Token Refresh and Reconnection**
**Challenge**: LiveKit tokens expire after 60 minutes. Network interruptions also cause disconnections. Need seamless reconnection without user intervention.

**Solution**: Implemented automatic token refresh detection. When connection fails with token expiration error, automatically request new token from backend and reconnect. Added reconnection UI state to inform users.

**Lesson**: Real-time applications need robust error handling and automatic recovery.

### 6. **SwiftUI + AppKit Integration**
**Challenge**: LiveKit's `VideoView` is an AppKit `NSView`, but the app uses SwiftUI. Need to bridge between frameworks.

**Solution**: Created `NSViewRepresentable` wrapper (`LiveKitVideoView`) to integrate AppKit views into SwiftUI hierarchy.

**Lesson**: Modern SwiftUI apps often need AppKit integration for low-level system APIs.


### 7. **Nginx Configuration Automation**
**Challenge**: Nginx configuration needed to be set up automatically on EC2 instance boot, but the Elastic IP isn't known until after instance creation.

**Solution**: Used Terraform `templatefile()` function to inject variables into `user-data.sh`. Set `server_name` to `_` initially (accepts any hostname), then manually update after EIP assignment if needed.

**Lesson**: Infrastructure automation requires flexibility—sometimes "good enough" initial state is acceptable.

---

## Comparison to Zoom and Microsoft Teams

### Similarities

#### Core Functionality
- ✅ Multi-participant video calls
- ✅ Audio/video mute controls
- ✅ Screen sharing
- ✅ Text chat
- ✅ Participant management
- ✅ Device selection (camera/mic/speaker)

#### User Experience
- ✅ Grid view for multiple participants
- ✅ Main stage view for active speaker/screen share
- ✅ Keyboard shortcuts
- ✅ Connection status indicators
- ✅ Speaking indicators

### Key Differences

#### Architecture
| Feature | Hermes | Zoom/Teams |
|---------|--------|------------|
| **Authentication** | Guest-only (no accounts) | User accounts required |
| **Backend** | Minimal stateless API | Complex backend with databases |
| **Media Infrastructure** | LiveKit Cloud (third-party) | Proprietary infrastructure |
| **Platform** | macOS only | Cross-platform (Windows, macOS, Linux, Web, Mobile) |
| **Deployment** | Self-hosted backend (AWS EC2) | Fully managed cloud service |

#### Feature Set
- ❌ **No cloud recording**: Hermes doesn't record meetings
- ❌ **No meeting scheduling**: No calendar integration
- ❌ **No breakout rooms**: Single room only
- ❌ **No waiting rooms**: Immediate join
- ❌ **No host controls**: All participants have equal permissions
- ❌ **No file sharing**: Chat only, no file attachments
- ❌ **No mobile apps**: macOS desktop only
- ❌ **No web client**: Native app required

#### Advantages of Hermes
- ✅ **Simpler**: No account creation, immediate join
- ✅ **Privacy-focused**: No user data storage, stateless backend
- ✅ **Lightweight**: Minimal dependencies, fast startup
- ✅ **Open architecture**: Uses standard WebRTC, can inspect/modify
- ✅ **Cost-effective**: Self-hosted backend, pay only for infrastructure

#### Advantages of Zoom/Teams
- ✅ **Mature**: Years of development, battle-tested
- ✅ **Feature-rich**: Recording, scheduling, integrations, mobile apps
- ✅ **Scalability**: Handles millions of concurrent users
- ✅ **Enterprise features**: SSO, compliance, admin controls
- ✅ **Cross-platform**: Works everywhere

### Use Cases

**Hermes is ideal for:**
- Small team meetings (2-10 participants)
- Quick ad-hoc video calls
- Privacy-conscious users
- macOS-only environments
- Custom integration projects
- Learning WebRTC/SwiftUI

**Zoom/Teams are better for:**
- Large enterprise deployments
- Cross-platform requirements
- Meeting recording needs
- Calendar integration
- Mobile users
- Compliance requirements (HIPAA, SOC 2, etc.)

---

## Project Structure

```
Hermes/
├── client-macos/           # macOS SwiftUI application
│   └── Hermes/
│       ├── App/           # App lifecycle and commands
│       ├── Views/         # SwiftUI views
│       ├── Services/      # Business logic and state
│       ├── LiveKit/       # LiveKit integration layer
│       ├── Models/        # Data models
│       └── Info.plist     # App configuration
├── backend/               # Node.js/Fastify API
│   ├── src/
│   │   ├── auth/         # JWT authentication
│   │   ├── routes/       # API endpoints
│   │   └── server.ts     # Fastify app setup
│   ├── Dockerfile        # Container definition
│   └── package.json      # Dependencies
├── infra/                # Infrastructure as Code
│   ├── terraform/        # Terraform configurations
│   └── deploy-backend.sh # Deployment script
└── scripts/              # Build and utility scripts
```

---

## Quick Start

### Prerequisites
- macOS 12.3+ (for ScreenCaptureKit)
- Xcode 14+
- Node.js 18+
- Docker (optional, for local backend)
- AWS account (for production deployment)
- LiveKit Cloud account (free tier available)

### Local Development

1. **Backend Setup**:
   ```bash
   cd backend
   cp env.example .env
   # Edit .env with your LiveKit credentials
   npm install
   npm run dev
   ```

2. **macOS Client**:
   ```bash
   open client-macos/Hermes.xcodeproj
   # Build and run in Xcode
   ```

3. **Permissions**: Grant Camera, Microphone, and Screen Recording permissions when prompted.

### Production Deployment

See `infra/DEPLOYMENT.md` for detailed AWS deployment instructions.

---

## License

ISC License (see individual files for details)

---

## Credits

Developed by **Hephaestus Systems** (Uner YILMAZ)

Built with:
- [LiveKit](https://livekit.io/) - WebRTC infrastructure
- [Fastify](https://www.fastify.io/) - Web framework
- [Terraform](https://www.terraform.io/) - Infrastructure automation

---

## Future Enhancements

Potential areas for improvement:
- HTTPS/SSL certificate automation
- Mobile clients (iOS/iPadOS)
- Web client (WebRTC in browser)
- Meeting recording
- File sharing in chat
