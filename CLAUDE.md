# PharoMCP

Pharo Smalltalk image exposed as an MCP (Model Context Protocol) HTTP endpoint. JSON-RPC 2.0
over HTTP, ZnServer delegate pattern.

## Architecture

- `MCPServer` -- HTTP server, CORS, delegates to `MCPRequestProcessor`. A notification answers
  202 with `Content-Length: 0`, which is what a keep-alive client waits for.
- `MCPRequestProcessor` -- routes a JSON-RPC method to a handler. The branches live in
  `MCPRequestProcessor class >> handlerSelectors`, one entry per method, and every handler takes
  the params and the id so the dispatch needs no case analysis.
- `MCPTool` -- one tool. Every tool of this server is a subclass of it in the `Tools` tag,
  stating its `name`, `description`, `title`, `inputSchema` and `annotations` as methods, plus an
  `outputSchema` when it answers structured data. `MCPTool >> call:`, which is all the processor
  sends, answers by sending `execute:`; a tool built from a block -- what a client registers --
  answers through the block in `MCPTool >> execute:` itself.
- `MCPPharoTools` -- class side only: one factory per tool answering an instance of its class, and
  the helpers the tools call (`classNamed:as:side:` and `packageNamed:` for every lookup,
  `listMethodsOn:side:`, `searchSource:inMethods:caseSensitive:`, ...). Add a tool: write its
  `MCPTool` subclass in the `Tools` tag, write the factory, include it in `allTools`.
- `MCPLogger` / `MCPLogEntry` and its subclasses -- per-request logging with announcements.
  `MCPLogEntry class >> entryClasses` names the subclasses; the logger detects over that list,
  not over `allSubclasses`.
- `MCPServerPresenter` / `MCPLogEntryPresenter` -- the server window, offered in the World menu.

## Packages

| Package | Contents |
|---|---|
| `PharoMCP` | Production code, 55 classes, of which 22 are the tool classes in the `Tools` tag |
| `PharoMCP-Examples` | One `<Subject>Examples` class per subject, holding the `<sampleInstance>` examples the inspector views and the tests read |
| `PharoMCP-Tests` | 359 tests over fourteen test classes, all pass |

Baseline groups: `default` (the server alone), `examples`, `tests`, `dev` (tests and MuTalk,
pinned to the release tag `v3.0.8`, never `master`).

Workspace source: `src/` in Tonel format, managed by Iceberg. The image is the source of truth:
change code through the MCP tools, never by writing a `.class.st` file.

## What the server answers

| Method | Answer |
|---|---|
| `initialize` | protocol version, the four capabilities, server info, instructions |
| `ping` | empty result |
| `tools/list`, `tools/call` | the 22 tools below |
| `completion/complete` | class, package and selector names for a `pharo://` reference, sorted, capped at 100 |
| `resources/list`, `resources/templates/list`, `resources/read` | `pharo://class/<Name>` answers definition, comment and every method source; `pharo://package/<Name>` answers each class with its comment |
| `prompts/list`, `prompts/get` | `red_green_refactor`, `bug_workflow`, `design_review` |

A GET endpoint with an SSE stream is the one structural gap, and with it `logging`, progress
notifications and `notifications/tools/list_changed`. Returning 405 on GET is allowed by the
specification, so nothing is broken meanwhile.

## Current tools (22)

`evaluate_pharo`, `list_classes`, `class_definition`, `class_hierarchy`, `class_comment`,
`class_create`, `class_rename`, `class_remove`, `list_methods`, `method_source`,
`compile_method`, `method_rename`, `method_move`, `delete_method`, `find_senders`,
`find_implementors`, `search_source`, `run_tests`, `run_critics`, `list_packages`,
`package_create`, `package_remove`

## Code conventions

- Class methods only in `MCPPharoTools`; it has no instances.
- Stream output with `<<` and `print:`, no string concatenation chains inside a stream.
- `ifNil:` and `ifAbsent:` inline, never `isNil ifTrue:`.
- `addAll:` rather than `do: add:` for building a collection.
- CR line endings in compiled methods. `compile_method` normalises a real LF on its own, and it
  does not decode an escape: a `\x0d` in the string is compiled as those four characters.
- No empty `on:do:` handler. Pharo's own `ReEmptyExceptionHandlerRule`, in `General-Rules`,
  flags it; the rule is not ours. An earlier copy of this file called it a custom rule of this
  project, which it has not been since commit c3f9028 removed the one we had.
- A class-side method is never named after a reflection selector (`name`, `binding`, `compile:`,
  `release`): it hides the selector Pharo's own tools send.
- Every class carries a class comment, with CR-only line endings.
- For every unit of work: red, green, refactor, example, view, then `run_critics`.
  `MCPConventionTest` holds the last three to their shape -- every example is a class-side unary
  method tagged `<sampleInstance>` that rebuilds its object, every inspector view takes the
  presenter builder as its only argument, and no view mutates its subject.

## Running

```smalltalk
| s |
s := MCPServer onPort: 7777.
s start.
Smalltalk at: #PharoMCPServer put: s.
```

## Testing

An abstract `TestCase` with concrete subclasses makes a package-level count lie, so ask per
class or build a suite from the concrete classes.

```smalltalk
MCPPharoToolsRunningTest suite run.   "91 tests"
MCPRequestProcessorTest suite run.    "47 tests"
MCPPharoToolsExtendedTest suite run.  "39 tests"
MCPServerTest suite run.              "32 tests"
MCPLogEntrySubclassTest suite run.    "26 tests"
MCPLoggerTest suite run.              "16 tests"
MCPToolSurfaceTest suite run.         "16 tests"
MCPToolArgumentDefaultsTest suite run. "15 tests"
MCPPharoToolsTest suite run.          "16 tests"
MCPLogEntryTest suite run.            "13 tests"
MCPConventionTest suite run.          "12 tests"
MCPToolTest suite run.                "27 tests"
MCPNullLoggerTest suite run.           "5 tests"
MCPLogEntryPresenterTest suite run.    "4 tests"
```
