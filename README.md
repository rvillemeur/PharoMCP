# PharoMCP

MCP (Model Context Protocol) server for Pharo Smalltalk. Runs locally over HTTP, letting Claude interact with a live Pharo image — evaluate code, browse classes, read method source.

**Requires:** Pharo 13 or later. It was developed on Pharo 13 and runs on Pharo 14 builds. Pharo 10 and 11 are not tested and the inspector views need the presenter builder that Pharo 13 introduced.

---

## Tools provided

### Evaluation

| Tool | Description |
|------|-------------|
| `evaluate_pharo` | Evaluate any Pharo expression, returns `printString` of result |

### Class browsing

| Tool | Description |
|------|-------------|
| `list_classes` | Search classes by name pattern (max 50 results) |
| `class_definition` | Get full class definition including superclass and instance variables |
| `class_hierarchy` | Show superclass chain and direct subclasses |
| `class_comment` | Get or set the comment (documentation) on a class |

### Class manipulation

| Tool | Description |
|------|-------------|
| `class_create` | Scaffold a new class with superclass, instance variables, and package |
| `class_remove` | Remove a class from the image (fails if subclasses exist) |

### Method browsing

| Tool | Description |
|------|-------------|
| `list_methods` | List all selectors on a class with their protocol, sorted by protocol then selector |
| `method_source` | Get method source code (instance or class side) |
| `find_implementors` | Find all classes that implement a given selector |
| `find_senders` | Find all methods that send a given message (capped at 100) |
| `search_source` | Search method source code for a text pattern across a class or package |

### Method manipulation

| Tool | Description |
|------|-------------|
| `compile_method` | Compile and install a method on a class (instance or class side) |
| `delete_method` | Remove a method from a class |
| `method_rename` | Rename a method selector on a class. Does not auto-update senders — use `find_senders` after renaming to locate callers. |
| `method_move` | Move a method from one class to another, preserving source and protocol. Fails if target already defines the selector. |

### Testing & quality

| Tool | Description |
|------|-------------|
| `run_tests` | Run a TestCase class, a single test method, or all tests in a package |
| `run_critics` | Run Renraku code critics on a class or package |

### Packages

| Tool | Description |
|------|-------------|
| `list_packages` | List packages with class and test class counts; optional name filter |
| `package_create` | Create a new package in the image (fails if already exists) |
| `package_remove` | Remove an empty package. Fails if the package still contains classes. |

---

## Loading the project

### Option A — From GitHub

Push this repository to GitHub, then in a Pharo 13 or later image open a Playground and evaluate:

```smalltalk
Metacello new
    baseline: 'PharoMCP';
    repository: 'github://rvillemeur/PharoMCP:main/src';
    load.
```

### Option B — From local disk (no GitHub needed)

1. Open the Pharo image you want to serve.
2. In a Playground, file in the packages from disk:

```smalltalk
| repoPath |
repoPath := '/path/to/PharoMCP'.   "← change this"

Metacello new
    baseline: 'PharoMCP';
    repository: 'tonel://', repoPath, '/src';
    load.
```

### Option C — Manual file-in

Not supported. Every tool is a class of its own, so the server is more than fifty classes and
filing in a handful of `.class.st` files leaves an image that cannot answer `tools/list`. Use
Option A or Option B: both load the baseline, which knows the whole set.

---

## Starting the server

In a Pharo Playground:

```smalltalk
"Start on default port 7777"
MCPServer default start.

"Or specify a port"
MCPServer onPort: 8888 start.

"Stop"
MCPServer default stop.
```

The server prints a confirmation to the Transcript. Keep the image running while you use Claude.

---

## Running tests

```smalltalk
"Run all tests"
(TestSuite forPackage: (RPackage named: 'PharoMCP-Tests')) run.

"Or from the Test Runner: open Tools > Test Runner, select PharoMCP-Tests"
```

---

## Connecting Claude Code

### Add the MCP server

```bash
claude mcp add pharo --transport http --url http://localhost:7777
```

Verify it appears:

```bash
claude mcp list
```

### Alternative: edit `~/.claude.json` directly

```json
{
  "mcpServers": {
    "pharo": {
      "type": "http",
      "url": "http://localhost:7777"
    }
  }
}
```

### Connecting Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "pharo": {
      "url": "http://localhost:7777"
    }
  }
}
```

Restart Claude Desktop after editing.

---

## Verifying the connection

In Claude Code, start a session and ask:

> "List the methods on the String class in Pharo."

Claude will call `list_methods` with `className: "String"` and return the results from your live image.

---

## Adding custom tools

```smalltalk
| server |
server := MCPServer default.

server registerTool: (MCPTool
    name: 'my_tool'
    description: 'Does something useful'
    schema: (Dictionary new
        at: 'type' put: 'object';
        at: 'properties' put: (Dictionary new
            at: 'input' put: (Dictionary new
                at: 'type' put: 'string';
                yourself);
            yourself);
        at: 'required' put: #('input');
        yourself)
    handler: [ :args |
        'You sent: ' , (args at: 'input') ]).

server start.
```

---

## Security

`evaluate_pharo` runs arbitrary Pharo code in your image with full privileges, so the socket this
server listens on is a remote shell in all but name. Three switches harden it. Each one defaults to
the behaviour earlier versions had, so updating the code breaks no existing deployment.

### Origin validation (always on)

A request whose `Origin` header is present and starts with none of `http://localhost`,
`http://127.0.0.1` or `http://[::1]` is answered 403, and an accepted request has its own origin
echoed in `Access-Control-Allow-Origin` rather than the `*` the server used to send. This is what
stops a web page you happen to visit from driving your image through scripted requests. A request
carrying no `Origin` header at all is not browser-driven and is served as before: that is how the
command-line client reaches the image. The allowed prefixes are
`MCPServer class >> allowedOriginPrefixes`.

### Bind the loopback interface only

The server binds every interface by default, because Claude Code running in a container reaches the
image through `host.docker.internal`. If every client runs on this machine, bind the loopback
interface instead:

```smalltalk
MCPServer default
	bindLoopbackOnly;
	start.
```

### Require a bearer token

No credential is required by default. Set one when the port is reachable by anything you do not
control:

```smalltalk
MCPServer default
	requireToken: 'a-long-random-string';
	start.
```

A request with no `Authorization` header, or with a different token, is then answered 401 with
`WWW-Authenticate: Bearer`. Give the client the same token as a header in `~/.claude.json`:

```json
{
  "mcpServers": {
    "pharo": {
      "type": "http",
      "url": "http://localhost:7777",
      "headers": { "Authorization": "Bearer a-long-random-string" }
    }
  }
}
```
