# RedisService — Coding Sample

## What this is

`redis_service.dart` is extracted from a mobile app I built (Flutter/Dart)
that relies on a Redis backend for live location and game-state data. This
class owns the connection lifecycle: it health-checks the backend on an
interval, exposes connectivity as observable state to the UI, and provides
a safe way for the rest of the app to run commands against Redis.

Note: this project is Flutter/Dart, not native Swift. I'm including it
because the underlying engineering patterns — reactive state management,
networking resilience, and resource lifecycle discipline map directly
onto MVVM work in Swift/SwiftUI, even though the syntax differs.
