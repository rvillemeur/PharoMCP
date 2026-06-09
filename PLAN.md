# PharoMCP Enhancement Plan

## Overview

Two phases:
1. Log entry subclasses + typed logger (structural refactor — no new behaviour)
2. Five new MCP tools (run_critics, find_senders, find_implementors, list_packages, class_hierarchy)

TDD throughout: tests written and confirmed RED before any implementation.
CR line endings in all `compile:classified:` calls (never LF).

---

## Phase 1 — Log Entry Subclasses + Typed Logger

### Motivation

`MCPLogEntry >> formatArguments:forTool:` is an 6-way dispatch chain.
Adding 5 new tools makes it 11-way. Replace with polymorphism now so each
new tool is one new class, not one more `ifTrue:` branch.

### 1.1 Subclass hierarchy

```
MCPLogEntry  (base — keeps extractedResponseText, formattedRequestJson/Response, displayMethod, displayArgs)
├── MCPEvalLogEntry            toolName: 'evaluate_pharo'
├── MCPListClassesLogEntry     toolName: 'list_classes'
├── MCPClassDefinitionLogEntry toolName: 'class_definition'
├── MCPListMethodsLogEntry     toolName: 'list_methods'
├── MCPMethodSourceLogEntry    toolName: 'method_source'
├── MCPRunTestsLogEntry        toolName: 'run_tests'
├── MCPInitializeLogEntry      method:   'initialize'
├── MCPToolsListLogEntry       method:   'tools/list'
└── MCPNotificationLogEntry    method starts with 'notifications/'
```

Each subclass overrides:
- `class >> toolName` — identifier used by typed logger for lookup
- `requestArgument` — tool-specific formatted param string for the detail pane

Base `MCPLogEntry`:
- Remove `formatArguments:forTool:` method entirely
- `requestArgument` becomes a generic fallback:
  returns first argument value (printString) or `''` if no args / not a tools/call

### 1.2 Typed Logger

`MCPLogger` gets:
- `entryClassForRequest: reqJson` — parses method + toolName, returns matching subclass
- `log:response:` updated to use `entryClassForRequest:` instead of always `MCPLogEntry`

Lookup logic (in order):
1. Parse `method` from request JSON. On parse error → `MCPLogEntry`.
2. If `method = 'tools/call'`: extract `params.name` (toolName).
   Search `MCPLogEntry allSubclasses` for `c toolName = toolName`. First match wins.
3. If `method` starts with `'notifications/'` → `MCPNotificationLogEntry`.
4. Otherwise: search subclasses for `c toolName = method` (covers initialize, tools/list).
5. No match → `MCPLogEntry`.

### 1.3 requestArgument per subclass

| Subclass | requestArgument |
|---|---|
| MCPEvalLogEntry | `args at: 'code'` |
| MCPListClassesLogEntry | `args at: 'pattern'` |
| MCPClassDefinitionLogEntry | `args at: 'className'` |
| MCPListMethodsLogEntry | `args at: 'className'` (+ side if present) |
| MCPMethodSourceLogEntry | `className >> #methodName` |
| MCPRunTestsLogEntry | package name OR className OR `className >> #selector` |
| MCPInitializeLogEntry | `''` |
| MCPToolsListLogEntry | `''` |
| MCPNotificationLogEntry | method name with `notifications/` prefix stripped |

### 1.4 TDD steps

**Step A — Write `MCPLogEntrySubclassTest` (RED)**

Test class per subclass behaviour:
- `testEvalLogEntryToolName` → `MCPEvalLogEntry toolName = 'evaluate_pharo'`
- `testEvalLogEntryRequestArgument` → creates entry with eval request, checks `requestArgument = '42 factorial'`
- Repeat pattern for all 9 subclasses
- `testMethodSourceRequestArgument` → `'String >> #size'`
- `testRunTestsWithPackage` → `'PharoMCP'`
- `testRunTestsWithSelector` → `'MCPToolTest >> #testToolCreation'`
- `testNotificationLogEntryStripsPrefix` → `requestArgument = ''`, `displayMethod = 'initialized'`

Test typed logger behaviour:
- `testLoggerCreatesEvalEntryForEvalRequest` → `logger log:response:` returns `MCPEvalLogEntry`
- `testLoggerCreatesNotificationEntryForNotification`
- `testLoggerCreatesBaseEntryForUnknownTool`
- `testLoggerCreatesInitializeEntryForInitialize`

**Step B — Implement subclasses (GREEN)**

For each subclass:
1. Install class via `MCPLogEntry << #MCPXxxLogEntry`
2. Compile `toolName` class-side method
3. Compile `requestArgument` instance method
4. Run `MCPLogEntrySubclassTest` → all green

**Step C — Implement typed logger (GREEN)**

1. Compile `MCPLogger >> entryClassForRequest:`
2. Update `MCPLogger >> log:response:` to use it
3. Run typed logger tests → green

**Step D — Refactor base class**

1. Remove `formatArguments:forTool:` from `MCPLogEntry`
2. Update `requestArgument` in base to generic fallback
3. Run ALL tests → green (MCPLogEntryTest, MCPLogEntrySubclassTest, MCPPharoToolsTest, MCPServerTest)

**Step E — Update source files**

Create `.class.st` files for all 9 new subclasses + update `MCPLogEntry.class.st`,
`MCPLogger.class.st`, and test file.

---

## Phase 2 — New Tools

Each tool follows the same TDD pattern:
1. Write test methods (RED)
2. Implement tool handler (GREEN)
3. Register in `MCPPharoTools.allTools`
4. Add corresponding log entry subclass (new class extending `MCPLogEntry`)
5. Update source files

### Tool 1: `run_critics`

**Schema:**
```
class_name  string  optional — class to critique
package     string  optional — all classes in package
```
Require at least one. `package` takes priority.

**Implementation:**
- For class: collect critiques for `aClass`, `aClass class`, and each method in both
- For package: iterate all classes in package, run per-class sweep
- Group output by class name
- Per critique: `[ruleName] title (entity)`
- Cap: 200 critiques, then truncate with count
- Error: class not found / not found / no critiques → say so

**Tests:**
- `testRunCriticsToolName` → `'run_critics'`
- `testRunCriticsSchemaHasClassNameAndPackage`
- `testRunCriticsOnValidClass` → returns string, no error prefix
- `testRunCriticsOnUnknownClass` → begins with `'Error'`
- `testRunCriticsOnUnknownPackage` → begins with `'Error'`
- `testRunCriticsOnMissingArgs` → begins with `'Error'`
- `testRunCriticsPackageOverridesClassName`

**Log entry subclass:** `MCPRunCriticsLogEntry`
- `toolName` → `'run_critics'`
- `requestArgument` → class name or package name

---

### Tool 2: `find_senders`

**Schema:**
```
selector  string  required
```

**Implementation:**
- `SystemNavigation default allSendersOf: selector asSymbol`
- Returns sorted list of `ClassName >> #selector` (instance) or `ClassName class >> #selector`
- Cap at 100; show count if more
- Error: empty selector

**Tests:**
- `testFindSendersToolName`
- `testFindSendersSchemaHasSelector`
- `testFindSendersReturnsResults` — find senders of `#printString` (guaranteed non-empty)
- `testFindSendersOnUnknownSelector` — returns 'No senders found'
- `testFindSendersOnMissingSelector` — begins with `'Error'`

**Log entry subclass:** `MCPFindSendersLogEntry`
- `requestArgument` → `selector` value

---

### Tool 3: `find_implementors`

**Schema:**
```
selector  string  required
```

**Implementation:**
- `SystemNavigation default allImplementorsOf: selector asSymbol`
- Returns sorted class names (instance side) and class-side implementors separately
- Cap at 100

**Tests:**
- `testFindImplementorsToolName`
- `testFindImplementorsSchemaHasSelector`
- `testFindImplementorsReturnsResults` — find implementors of `#printOn:` (non-empty)
- `testFindImplementorsOnUnknownSelector` — 'No implementors found'
- `testFindImplementorsOnMissingSelector` — begins with `'Error'`

**Log entry subclass:** `MCPFindImplementorsLogEntry`
- `requestArgument` → `selector` value

---

### Tool 4: `list_packages`

**Schema:**
```
pattern  string  optional — substring filter on package name (case-insensitive)
```

**Implementation:**
- `Smalltalk packageOrganizer packages`
- Each line: `PackageName (N classes, M test classes)`
- Sort alphabetically
- If pattern given: filter first
- Cap at 200

**Tests:**
- `testListPackagesToolName`
- `testListPackagesSchemaHasPattern`
- `testListPackagesReturnsAllWhenNoPattern` — result includes 'PharoMCP'
- `testListPackagesFiltersOnPattern` — pattern 'PharoMCP' returns only 'PharoMCP' line
- `testListPackagesEmptyPatternReturnsAll` — same as no pattern

**Log entry subclass:** `MCPListPackagesLogEntry`
- `requestArgument` → `pattern` value or `''`

---

### Tool 5: `class_hierarchy`

**Schema:**
```
class_name  string  required
```

**Implementation:**
- Superclass chain: `aClass allSuperclasses` (from direct super to `ProtoObject`)
- Direct subclasses: `aClass subclasses` sorted by name
- Format:
  ```
  Superclasses (root → class):
    ProtoObject > Object > Collection > ... > OrderedCollection

  Direct subclasses (N):
    SortedCollection
    WeakOrderedCollection
    ...
  ```

**Tests:**
- `testClassHierarchyToolName`
- `testClassHierarchySchemaHasClassName`
- `testClassHierarchyOnValidClass` — includes 'Object' in result
- `testClassHierarchyOnUnknownClass` — begins with `'Error'`
- `testClassHierarchyOnMissingClassName` — begins with `'Error'`
- `testClassHierarchyShowsSubclasses` — `OrderedCollection` result includes `SortedCollection`

**Log entry subclass:** `MCPClassHierarchyLogEntry`
- `requestArgument` → class name

---

## File changes summary

### New files
```
src/PharoMCP/
  MCPEvalLogEntry.class.st
  MCPListClassesLogEntry.class.st
  MCPClassDefinitionLogEntry.class.st
  MCPListMethodsLogEntry.class.st
  MCPMethodSourceLogEntry.class.st
  MCPRunTestsLogEntry.class.st
  MCPInitializeLogEntry.class.st
  MCPToolsListLogEntry.class.st
  MCPNotificationLogEntry.class.st
  MCPRunCriticsLogEntry.class.st
  MCPFindSendersLogEntry.class.st
  MCPFindImplementorsLogEntry.class.st
  MCPListPackagesLogEntry.class.st
  MCPClassHierarchyLogEntry.class.st
  MCPLogEntrySubclassTest.class.st
  MCPPharoToolsExtendedTest.class.st   (new tools tests)
```

### Modified files
```
  MCPLogEntry.class.st          remove formatArguments:forTool:, update requestArgument
  MCPLogger.class.st            add entryClassForRequest:, update log:response:
  MCPPharoTools.class.st        add 5 new tools + allTools update
  MCPServerTest.class.st        add testInitializesWithAllTools assertion
```

---

## Completion criteria

- Zero LF in any compiled method (check with `includes: Character lf` sweep)
- All test suites green: MCPLogEntryTest, MCPLogEntrySubclassTest, MCPPharoToolsTest,
  MCPPharoToolsExtendedTest, MCPServerTest, MCPToolTest, MCPRequestProcessorTest
- `MCPServerPresenter open` shows correct subclass names in Method column
- Each new tool callable via live MCP and returns sensible output
