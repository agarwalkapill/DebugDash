# DebugDash

![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)
![iOS](https://img.shields.io/badge/iOS-15.0%2B-blue?style=flat-square)
![SPM](https://img.shields.io/badge/SPM-compatible-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)

An embedded HTTP debugging server for iOS apps. Drop it into any debug build and get a browser-accessible dashboard for inspecting runtime state — no Mac tools required, no USB cable needed.

---

## Features

- 🌐 **Network Browser** — captures all HTTP/HTTPS traffic routed through a registered `URLSession`, with full request/response headers, bodies, timing, and cURL export
- 🛡️ **Network Interceptor** — create rules to mock any URL pattern with a custom status code and response body; toggle rules on/off individually without restarting the app
- 📦 **UserDefaults Browser** — live view of all UserDefaults suites; edit, delete, or add keys directly from the browser; export/import as JSON
- 🗄️ **Database Browser** — auto-discovers `.sqlite` files in the app sandbox; paginated table viewer, schema inspector, and raw SQL console

---

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15+

---

## Installation

Add via Swift Package Manager in Xcode: **File → Add Package Dependencies**

```
https://github.com/your-username/DebugDash
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/DebugDash", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["DebugDash"])
]
```

---

## Quick Start

**Step 1 — Configure and start the server** (typically in `AppDelegate` or `App.init`):

```swift
import DebugDash

var config = Configuration()
config.port = 8080
DebugDash.configure(with: config)
DebugDash.startServer()
DebugDash.showToggle() // optional floating button
```

**Step 2 — Register the URL protocol** to capture network traffic:

```swift
let config = URLSessionConfiguration.default
config.protocolClasses = [DebugDash.urlProtocolClass] + (config.protocolClasses ?? [])
let session = URLSession(configuration: config)
// Use this session for all network calls you want to capture
```

**Step 3 — Open the dashboard** in any browser on the same Wi-Fi network:

```
http://<device-local-ip>:8080/dashboard
```

Or on simulator: `http://localhost:8080/dashboard`

---

## Configuration Reference

| Property | Type | Default | Description |
|---|---|---|---|
| `port` | `UInt16` | `8080` | Port for the HTTP server |
| `suiteNames` | `Set<String>` | `[]` | App Group suites to expose (e.g. `group.com.myapp.shared`). Regular named suites are auto-discovered — only needed for suites stored in a shared container |
| `databasePaths` | `[String]` | `[]` | Extra SQLite file paths to include in Database Browser |
| `includeStandardDefaults` | `Bool` | `true` | Whether to expose `UserDefaults.standard` |
| `maxConnections` | `Int` | `5` | Maximum concurrent dashboard connections |
| `allowWebModifications` | `Bool` | `true` | Permit writes from the dashboard (UserDefaults edits, SQL execution) |
| `persistServerStateAcrossLaunches` | `Bool` | `true` | Auto-restart server on next launch if it was running |

---

## Feature Details

### Network Browser
Captures HTTP and HTTPS requests via `URLProtocol`. Requests are stored in an in-memory ring buffer (500 entries, FIFO eviction). Each entry includes the full request/response headers, body (truncated at 512 KB), duration in ms, and a ready-to-paste cURL command.

Endpoints: `GET /api/network`, `GET /api/network/{id}`, `GET /api/network/stats`, `DELETE /api/network`

### Network Interceptor
Rule-based mock system. Each rule matches on URL pattern (substring) and optionally HTTP method. When a request matches an enabled rule, the real network call is skipped and the mock response is served directly to the app.

Rules are persisted as JSON in `Library/Caches/DebugDash/` and survive app restarts. The master toggle and per-rule toggles are independent.

Endpoints: `GET/POST /api/interceptor/rules`, `PUT/DELETE /api/interceptor/rules/{id}`, `POST /api/interceptor/rules/{id}/toggle`, `POST /api/interceptor/toggle`

### UserDefaults Browser
Reads all keys from `UserDefaults.standard` and all named suites. Named suites are **auto-discovered** by scanning `Library/Preferences/` for `.plist` files — no configuration needed for suites stored in the app's own sandbox. The exception is App Group suites (`group.*`), which are stored in a shared container outside the sandbox; declare those manually via `Configuration.suiteNames`. Values are serialised to strings for display; the editor converts them back to the correct type on save. Supports: `String`, `Int`, `Double`, `Bool`, `Date`, `Data`, `Array`, `Dictionary`.

Endpoints: `GET /api/defaults`, `PUT /api/defaults/{key}`, `DELETE /api/defaults/{key}`, `GET /api/suites`, `GET /api/export`, `POST /api/import`

### Database Browser
Scans `Documents/`, `Library/`, `Caches/`, and `tmp/` for `.sqlite` files at startup, plus any paths added via `Configuration.databasePaths`. Opens databases read-only (WAL mode). The SQL console runs arbitrary queries when `allowWebModifications` is `true`.

Endpoints: `GET /api/databases`, `GET /api/databases/tables`, `GET /api/databases/table-data`, `POST /api/databases/query`

---

## Known Limitations

- Only captures traffic routed through a `URLSession` that has `DebugDash.urlProtocolClass` registered. System-level requests (push notifications, CloudKit sync) are not captured.
- WebSocket connections are not captured.
- The dashboard uses HTTP, not HTTPS. Do not use on untrusted networks.
- Not intended for production builds — gate behind `#if DEBUG` or a build flag.

---

## Usage Recommendation

```swift
#if DEBUG
DebugDash.configure(with: config)
DebugDash.startServer()
#endif
```

---

## Contributing

Pull requests welcome. Please keep changes scoped to one feature per PR and ensure `swift build` passes with no warnings before submitting.

---

## License

MIT © 2025
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What Is DebugDash?

DebugDash is a powerful debugging tool that embeds an HTTP server directly into your iOS app. It serves a browser-accessible dashboard at `http://localhost:8080/dashboard` where you can inspect and modify your app's runtime state in real-time.

### Current Status: Phase 1 Complete ✅

**Phase 1 (Core Infrastructure)** is fully implemented:
- ✅ NWListener-based HTTP server
- ✅ Request parsing and routing
- ✅ Minimal HTML dashboard
- ✅ Public API via `DebugDash` enum
- ✅ Floating toggle button
- ✅ Server state persistence across launches

### Coming Soon (Phases 2-8)

| Phase | Feature | Status |
|---|---|---|
| 7 | Complete Dashboard SPA | 🔜 Next |
| 2 | UserDefaults Browser | ⏳ Planned |
| 3 | SQLite Database Browser | ⏳ Planned |
| 4 | Network Capture & Mocking | ⏳ Planned |
| 5 | Session Recording | ⏳ Planned |
| 6 | JSON Tools | ⏳ Planned |
| 8 | Example App & Polish | ⏳ Planned |

---

## Installation

### Swift Package Manager

Add DebugDash to your project via Xcode:

```
File > Add Package Dependencies
```

Enter the repository URL or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/DebugDash.git", from: "1.0.0")
]
```

---

## Quick Start

### 1. Import and Configure

```swift
import DebugDash

// In your AppDelegate or App struct
DebugDash.configure(with: Configuration(
    port: 8080,
    persistServerStateAcrossLaunches: true
))
```

### 2. Start the Server

```swift
DebugDash.startServer()

// The server is now accessible at:
// http://localhost:8080/dashboard
```

### 3. Show the Toggle Button (Optional)

```swift
// In your main view or window scene
DebugDash.showToggle()
```

That's it! Open your browser and navigate to `http://localhost:8080/dashboard`.

---

## Usage

### Basic API

```swift
import DebugDash

// Configure (call once at app launch)
DebugDash.configure()

// Start the server
DebugDash.startServer()

// Stop the server
DebugDash.stopServer()

// Check server status
if DebugDash.isRunning {
    print("Dashboard URL: \(DebugDash.dashboardURL?.absoluteString ?? "")")
}

// Show floating toggle button
DebugDash.showToggle()

// Hide toggle button
DebugDash.hideToggle()
```

### Advanced Configuration

```swift
let config = Configuration(
    port: 8080,
    suiteNames: ["com.myapp.settings"], // UserDefaults suites to expose
    databasePaths: ["/path/to/app.db"], // SQLite databases to browse
    includeStandardDefaults: true,
    maxConnections: 5,
    allowWebModifications: true, // Allow CRUD from web UI
    persistServerStateAcrossLaunches: true // Auto-start server on next launch
)

DebugDash.configure(with: config)
```

---

## Architecture

### Design Principles

- **Zero external dependencies** — All HTML/CSS/JS embedded as Swift strings
- **Never crash the host app** — All operations wrapped in do-catch
- **No swizzling** — Network capture uses URLProtocol API (coming in Phase 4)
- **Debug builds only** — Compile behind `#if DEBUG`

### Components

```
┌─────────────────────────────────────────────────┐
│           DebugDash (Public API)                │
│                                                 │
│  configure() · startServer() · stopServer()     │
│  showToggle() · hideToggle() · isRunning       │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│         DebugDashManager (Singleton)            │
│                                                 │
│  • WebServer lifecycle management              │
│  • Configuration storage                       │
│  • State persistence (UserDefaults)            │
│  • Toggle UI management                        │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│            WebServer (NWListener)               │
│                                                 │
│  • TCP server on localhost:8080                │
│  • HTTP request parsing                        │
│  • Request routing                             │
│  • HTML/JSON response serving                  │
│  • CORS headers                                │
└─────────────────────────────────────────────────┘
```

---

## Files Structure

```
Sources/DebugDash/
├── DebugDash.swift              # Public API enum
├── Configuration.swift          # Public config struct
├── Core/
│   ├── DebugDashManager.swift   # Singleton orchestrator
│   ├── WebServer.swift          # NWListener HTTP server
│   └── ToggleView.swift         # Floating toggle button
├── Features/                    # Feature modules (Phase 2-6)
│   ├── UserDefaults/
│   ├── Database/
│   ├── Network/
│   └── Session/
└── Dashboard/                   # HTML generation (Phase 7)
```

---

## API Reference

### Configuration

| Property | Type | Default | Description |
|---|---|---|---|
| `port` | `UInt16` | 8080 | HTTP server port |
| `suiteNames` | `Set<String>` | [] | UserDefaults suites to include |
| `databasePaths` | `[String]` | [] | SQLite database paths |
| `includeStandardDefaults` | `Bool` | true | Include UserDefaults.standard |
| `maxConnections` | `Int` | 5 | Max concurrent connections |
| `allowWebModifications` | `Bool` | true | Allow write operations |
| `persistServerStateAcrossLaunches` | `Bool` | true | Auto-start on next launch |

### DebugDash Enum

| Method | Description |
|---|---|
| `configure(with:)` | Configure with custom settings |
| `startServer()` | Start the HTTP server |
| `stopServer()` | Stop the HTTP server |
| `showToggle()` | Show floating toggle in key window |
| `showToggle(in:)` | Show toggle in specific scene |
| `hideToggle()` | Hide the toggle button |
| `isRunning` | Server status (Bool) |
| `dashboardURL` | Dashboard URL (URL?) |
| `urlProtocolClass` | URLProtocol for network capture (AnyClass?) |

---

## Verification

### Test the Server

1. Run the example app (see `Examples/ExampleApp/`)
2. Open your browser to `http://localhost:8080/dashboard`
3. You should see the DebugDash welcome page

### Test the Toggle Button

1. Look for the floating button in the bottom-right corner
2. Tap to stop the server (button turns red)
3. Tap again to restart (button turns green)

### Test State Persistence

1. Start the server via toggle or API
2. Terminate the app
3. Relaunch the app
4. Server should auto-start (if `persistServerStateAcrossLaunches: true`)

---

## Requirements

- **iOS 15.0+**
- **Swift 5.9+**
- **Xcode 14.0+**

---

## Debug Builds Only

DebugDash is intended for development and QA builds only. Wrap initialization in a debug flag:

```swift
#if DEBUG
import DebugDash

DebugDash.configure()
DebugDash.startServer()
#endif
```

---

## Roadmap

- [x] Phase 0: Project scaffolding
- [x] Phase 1: Core HTTP server infrastructure
- [ ] Phase 7: Complete dashboard SPA (dark theme, navigation)
- [ ] Phase 2: UserDefaults browser (CRUD, export/import)
- [ ] Phase 3: SQLite database browser (table viewer, SQL console)
- [ ] Phase 4: Network capture & request mocking
- [ ] Phase 5: Session recording (screenshots + logs)
- [ ] Phase 6: JSON tools (format, validate, diff)
- [ ] Phase 8: Example app & documentation polish

---

## License

MIT License - see [LICENSE](LICENSE) for details

---

## Contributing

This is a personal portfolio project. Phase-by-phase implementation following the [ARCHITECTURE.md](ARCHITECTURE.md) blueprint.

---

**Built with ❤️ for iOS developers who love clean debugging tools**
WebInspector Debugger for iOS Apps
