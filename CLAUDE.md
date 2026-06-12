# PharoMCP

Pharo Smalltalk image exposed as an MCP (Model Context Protocol) HTTP endpoint. JSON-RPC 2.0 over HTTP. ZnServer delegate pattern.

## Architecture

- `MCPServer` — HTTP server, CORS, delegates to `MCPRequestProcessor`
- `MCPRequestProcessor` — routes JSON-RPC method calls to registered `MCPTool` instances
- `MCPPharoTools` — all tool factory methods (class-side). Add a tool: implement a factory method, include in `allTools`
- `MCPLogger` / `MCPLogEntry` / subclasses — per-request logging with announcement
- `ReEmptyExceptionHandlerRule` — custom Renraku rule, flags empty `on:do:` handlers

## Packages

| Package | Contents |
|---|---|
| `PharoMCP` | Production code |
| `PharoMCP-Tests` | 177 tests, all pass |

Workspace source: `src/` (Tonel format). Keep in sync with image after changes.

## Current tools (14)

`evaluate_pharo`, `list_classes`, `class_definition`, `method_source`, `compile_method`, `delete_method`, `list_methods`, `search_source`, `run_tests`, `run_critics`, `find_senders`, `find_implementors`, `list_packages`, `class_hierarchy`

## Code conventions

- Class methods only in `MCPPharoTools` (no instances)
- Stream output with `<<` and `print:` — no string concat chains inside streams
- `ifNil:` / `ifAbsent:` inline — no `isNil ifTrue:`
- `addAll:` not `do: add:` for building collections
- CR line endings in compiled methods (`\r` not `\n`) — post-hook normalises automatically
- No empty `on:do:` handlers — `ReEmptyExceptionHandlerRule` enforces this

## Pending work (priority order)

1. ~~**`search_source` tool**~~ — done.

2. ~~**`delete_method` tool**~~ — done.

3. ~~**Extended test for `compile_method`**~~ — done (also covers `delete_method` and `search_source`). — `MCPPharoToolsExtendedTest` covers all other tools via processor interface; `compile_method` missing.

4. ~~**`class_create` tool**~~ — done (6 tests added).

6. ~~**`list_methods` protocol info**~~ — done (already in image, 4 tests added).

7. ~~**`run_tests` duration**~~ — done (already in image, 2 tests added).

8. ~~**Check `MCPExample.class.st`**~~ — done, image and file match.

## Running

```smalltalk
| s |
s := MCPServer onPort: 7777.
s start.
Smalltalk at: #PharoMCPServer put: s.
```

## Testing

```smalltalk
MCPPharoToolsRunningTest suite run.  "33 tests"
MCPServerTest suite run.             "18 tests"
MCPLoggerTest suite run.             "16 tests"
ReEmptyExceptionHandlerRuleTest suite run. "7 tests"
```
