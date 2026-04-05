# Plugins

ASC supports a plugin system based on compiled `.plugin` bundles (dylibs) that extend the CLI with server routes, UI components, CLI commands, and domain affordances. Plugins are discovered from `~/.asc/plugins/` at startup.

For browsing and installing plugins from a marketplace, see [Plugin Market](market.md).

## Plugin Bundle Structure

```
~/.asc/plugins/ASCPro.plugin/
├── manifest.json              # metadata: name, version, server dylib, UI scripts
├── ASCPro.dylib               # compiled dynamic library
└── ui/
    └── sim-stream.js          # web UI scripts (loaded by command-center)
```

### manifest.json

```json
{
  "name": "ASC Pro",
  "version": "1.0",
  "server": "ASCPro.dylib",
  "ui": ["ui/sim-stream.js"]
}
```

## CLI Usage

### `asc plugins list`

List installed dylib plugins.

```bash
asc plugins list --pretty
```

### `asc plugins install --name <name>`

Install a plugin from the marketplace.

```bash
asc plugins install --name asc-pro
```

### `asc plugins uninstall --name <name>`

Remove an installed plugin bundle.

```bash
asc plugins uninstall --name ASCPro
```

### `asc plugins market list`

Browse all available plugins. See [Plugin Market](market.md).

### `asc plugins market search --query <text>`

Search marketplace by keyword. See [Plugin Market](market.md).

## Plugin Protocol

Plugins export a C entry point and conform to `ASCPluginBase`:

```swift
@_cdecl("ascPlugin")
public func ascPlugin() -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(MyPlugin()).toOpaque()
}

public final class MyPlugin: NSObject, ASCPluginBase {
    public let name = "My Plugin"
    public var commands: [Any] { [] }

    public func configureRoutes(_ router: Any) {
        // Register HTTP/WebSocket routes
    }
}
```

## AffordanceRegistry

Plugins extend domain model affordances at runtime using structured `Affordance` values that render to both CLI commands and REST `_links`:

```swift
AffordanceRegistry.register(Simulator.self) { id, props in
    guard props["isBooted"] == "true" else { return [] }
    return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
}
```

This produces:
- **CLI**: `"stream": "asc simulators stream --udid <id>"`
- **REST**: `"stream": {"href": "/api/v1/simulators/<id>/stream", "method": "POST"}`

## Architecture

```
PluginLoader.discover()
  → scans ~/.asc/plugins/ for .plugin, .framework, .dylib
  → loads via dlopen/dlsym("ascPlugin")
  → returns [LoadedPlugin] with name, slug, uiScripts

ASCWebServer.buildRouter()
  → calls plugin.configureRoutes(routerPtr)
  → serves plugin UI scripts at /api/plugins/{slug}/ui/*
  → GET /api/plugins returns manifest list for web app
```
