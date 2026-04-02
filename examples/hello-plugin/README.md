# Hello Plugin — ASC Plugin Example

A minimal example plugin for [ASC CLI](https://github.com/tddworks/asc-cli). Fork this as a starting point for your own plugin.

## What it does

- Registers a **"Greet" button** on every App via `AffordanceRegistry`
- Adds `GET /api/hello` and `GET /api/hello/greet?name=X` routes
- Injects a UI script that handles the affordance button click

## The Affordance Flow

This is the key pattern for plugin developers:

```
┌─ Swift (plugin startup) ─────────────────────────────────────┐
│                                                               │
│  AffordanceRegistry.register(App.self) { id, props in        │
│      ["greet": "asc hello greet --app-id \(id)"]            │
│  }                                                            │
│                                                               │
│  → Every App now has a "greet" affordance in its JSON output │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌─ Web App (command-center) ───────────────────────────────────┐
│                                                               │
│  Renders affordances as buttons:                             │
│  ┌──────────────────────────────────────┐                    │
│  │  PhotoSync Pro          [Greet]      │                    │
│  │  TaskFlow               [Greet]      │                    │
│  └──────────────────────────────────────┘                    │
│                                                               │
│  User clicks "Greet" → dispatches to handler                 │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌─ Plugin UI (hello.js) ──────────────────────────────────────┐
│                                                               │
│  window.appAffordanceHandlers['greet'] = async (id, name) => │
│      fetch(`/api/hello/greet?name=${name}`)                  │
│      showToast(data.message)                                  │
│  }                                                            │
│                                                               │
│  → Calls plugin route, shows "Hello, PhotoSync Pro!"         │
└───────────────────────────────────────────────────────────────┘
```

## Build & Install

```bash
# Prerequisites: build asc-cli first
cd /path/to/asc-cli
swift build

# Then build the plugin
cd examples/hello-plugin
make install
```

## Test it

```bash
# Start the web server (plugin auto-discovered)
asc web-server

# In another terminal
curl http://localhost:8420/api/hello
# → {"message":"Hello from the example plugin!","timestamp":"2026-04-02T12:00:00Z"}

curl "http://localhost:8420/api/hello/greet?name=Developer"
# → {"message":"Hello, Developer!"}
```

Open the command-center — you'll see "Greet" buttons on apps.

## Project Structure

```
hello-plugin/
├── Package.swift                     # depends on ASCPlugin + ASCKit + Hummingbird
├── Makefile                          # build + install
├── Sources/HelloPlugin/
│   └── HelloPlugin.swift             # entry point + routes + AffordanceRegistry
└── plugin/
    ├── manifest.json                 # plugin metadata
    └── ui/
        └── hello.js                  # affordance handler for web UI
```

## Key Concepts

### 1. Entry point + AffordanceRegistry

```swift
@_cdecl("ascPlugin")
public func ascPlugin() -> UnsafeMutableRawPointer {
    let plugin = HelloPlugin()

    // Add a "greet" button to every App in the web UI
    AffordanceRegistry.register(App.self) { id, props in
        let name = props["name"] ?? id
        return ["greet": "asc hello greet --app-id \(id) --name \(name)"]
    }

    return Unmanaged.passRetained(plugin).toOpaque()
}
```

### 2. Server routes

```swift
public func configureRoutes(_ routerPtr: Any) {
    guard let ptr = routerPtr as? UnsafeMutableRawPointer else { return }
    let router = Unmanaged<ASCRouter>.fromOpaque(ptr).takeUnretainedValue()

    router.get("/api/hello/greet") { request, _ in
        let name = request.uri.queryParameters.get("name") ?? "World"
        // return JSON response
    }
}
```

### 3. UI affordance handler

```javascript
// hello.js — matches the "greet" key from AffordanceRegistry
window.appAffordanceHandlers['greet'] = async function(appId, appName) {
    const resp = await fetch(`/api/hello/greet?name=${appName}`);
    const data = await resp.json();
    showToast(data.message, 'success');
};
```

### 4. manifest.json

```json
{
  "name": "Hello Plugin",
  "version": "1.0",
  "server": "HelloPlugin.dylib",
  "ui": ["ui/hello.js"]
}
```

## Publish to marketplace

1. `make build`
2. `cd .build && zip -r HelloPlugin.plugin.zip HelloPlugin.plugin/`
3. Upload to a GitHub release
4. Add entry to [tddworks/asc-registry](https://github.com/tddworks/asc-registry)
