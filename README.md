# PharoMCP

MCP (Model Context Protocol) server for Pharo Smalltalk. Runs locally over HTTP, letting Claude interact with a live Pharo image — evaluate code, browse classes, read method source.

**Requires:** Pharo 10 or 11.

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

Push this repository to GitHub, then in a Pharo 10/11 image open a Playground and evaluate:

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

### Option C — Manual file-in (quickest for testing)

In the Pharo image, open a Playground and evaluate each class definition file in order:

1. `src/PharoMCP/MCPTool.class.st`
2. `src/PharoMCP/MCPRequestProcessor.class.st`
3. `src/PharoMCP/MCPPharoTools.class.st`
4. `src/PharoMCP/MCPServer.class.st`

Use `File > File In…` or drag-and-drop onto the image.

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

## Security note

`evaluate_pharo` runs arbitrary Pharo code in your image with full privileges. Run only on `localhost` and do not expose port 7777 to external networks.
