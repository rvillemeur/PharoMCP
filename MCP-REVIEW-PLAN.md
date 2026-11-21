# PharoMCP Review Plan

Written 2026-11-21, after an audit of the implementation against the MCP specification
revision 2025-11-25 and against the project's current code standards.

The audit found three kinds of gap: a security exposure that follows from an HTTP endpoint
with arbitrary code evaluation on it, protocol rules the server does not yet follow, and
drift from the standards the other projects in this image now hold themselves to (examples
in a sibling package, inspector views, meta tests, baseline groups).

Each unit below names the failing test to write first, the change, and what makes it done.
Unit order is deliberate: nothing in phases 1 to 3 may break the connection this session
depends on, so every security switch lands turned off and is documented rather than
enabled.

Reference: <https://modelcontextprotocol.io/specification/2025-11-25>

---

## Phase 1 — Security defaults

### Motivation

`evaluate_pharo` executes arbitrary Pharo code, which is arbitrary code on the host as the
user running the image. The server today listens on every interface (`ZnServer` with no
`bindingAddress`), answers `Access-Control-Allow-Origin: *`, validates no `Origin` header
and asks for no credential. Two consequences follow:

- anyone who can reach port 7777 controls the image and the account it runs under;
- any web page the user opens can POST JSON-RPC to `http://localhost:7777/` and read the
  reply, which is code execution from a browser tab.

The specification states that servers "MUST validate the `Origin` header on all incoming
connections", "MUST respond with HTTP 403 Forbidden" when the header is present and
invalid, "SHOULD bind only to localhost (127.0.0.1)" when running locally, and "SHOULD
implement proper authentication for all connections".

Binding to loopback cannot be the default here: the MCP client runs in a container and
reaches the image through `host.docker.internal`, so a loopback-only socket would refuse
it. The binding and the token therefore become switches with today's behaviour as the
default, and the README explains which to turn on in which deployment.

### 1.1 Origin validation

- Test: `MCPServerTest >> testRequestWithForeignOriginIsForbidden` — a POST carrying
  `Origin: https://evil.example` answers 403 and no JSON-RPC result.
- Test: `MCPServerTest >> testRequestWithoutOriginIsAccepted` — the header is absent, the
  request is served (this is the case of the container client).
- Test: `MCPServerTest >> testRequestWithLocalOriginIsAccepted` — `http://localhost:1234`
  is served, and the response echoes that origin rather than `*`.
- Change: `MCPServer >> isOriginAllowed:` tested against a class-side
  `allowedOriginPrefixes` constant; `handleRequest:` answers `self forbiddenResponse` when
  an origin is present and not allowed; `addCorsHeadersTo:` echoes the request's origin
  when there is one and omits the header otherwise.
- Done when: the three tests pass and no response carries `Access-Control-Allow-Origin: *`.

### 1.2 Loopback binding switch

- Test: `MCPServerTest >> testBindingAddressDefaultsToAllInterfaces` — states today's
  behaviour, so a later change to it cannot be silent.
- Test: `MCPServerTest >> testBindLoopbackOnlySetsBindingAddress` — after
  `bindLoopbackOnly`, the server's binding address is 127.0.0.1.
- Change: `MCPServer >> bindingAddress:` and `>> bindLoopbackOnly`, applied to the
  `ZnServer` in `start`; class-side `loopbackAddress` constant.
- Done when: both tests pass and the README names the two deployments (container client:
  all interfaces plus a token; same-host client: `bindLoopbackOnly`).

### 1.3 Bearer token switch

- Test: `MCPServerTest >> testTokenlessServerAcceptsRequestWithoutAuthorization` — the
  default server is unchanged.
- Test: `MCPServerTest >> testServerWithTokenRejectsMissingAuthorization` — 401.
- Test: `MCPServerTest >> testServerWithTokenAcceptsMatchingBearer` — served.
- Change: `MCPServer >> requireToken:` storing nil by default; `authorizationHeaderName`
  and `bearerPrefix` as class-side constants; comparison in constant time is not attempted,
  and the reason (a local single-client endpoint) is stated in the method comment.
- Done when: the three tests pass and the README shows the `~/.claude.json` header entry
  that goes with the switch.

---

## Phase 2 — Protocol conformance with revision 2025-11-25

### 2.1 Protocol version negotiation

- Test: `MCPRequestProcessorTest >> testInitializeEchoesSupportedVersionRequestedByClient`
  — a client asking for `2025-06-18` is answered `2025-06-18`.
- Test: `MCPRequestProcessorTest >> testInitializeAnswersLatestForUnknownVersion` — a
  client asking for `1999-01-01` is answered the server's latest supported revision.
- Test: `MCPRequestProcessorTest >> testInitializeAnswersLatestWhenClientSendsNoVersion`.
- Change: `MCPRequestProcessor class >> supportedProtocolVersions` and
  `>> latestProtocolVersion`; `handleInitialize:id:` reads `params at: 'protocolVersion'`
  and negotiates. The hardcoded `'2024-11-05'` disappears from the method body, which also
  settles the no-magic-values rule for revision strings.
- Done when: the three tests pass and `2024-11-05` appears in no method but the constant.

### 2.2 `ping`

- Test: `MCPRequestProcessorTest >> testPingAnswersEmptyResult` — `{"method":"ping"}` with
  an id answers `result` equal to an empty object, not a `-32601` error.
- Change: a `ping` branch in `dispatchRequest:`.
- Done when: the test passes. The specification is a MUST here, and a client that pings for
  liveness may otherwise drop the connection as stale.

### 2.3 `MCP-Protocol-Version` request header

- Test: `MCPServerTest >> testUnsupportedProtocolVersionHeaderIsBadRequest` — a POST with
  `MCP-Protocol-Version: 1999-01-01` answers 400.
- Test: `MCPServerTest >> testMissingProtocolVersionHeaderIsAccepted` — served, because the
  specification says to assume `2025-03-26` when the header is absent.
- Change: a check in `handleRequest:` against `supportedProtocolVersions`; class-side
  `protocolVersionHeaderName` and `assumedProtocolVersion` constants.
- Done when: both tests pass.

### 2.4 Tool input validation reports a tool error

- Test: `MCPRequestProcessorTest >> testMissingRequiredArgumentIsToolError` — a
  `tools/call` for `evaluate_pharo` with no `code` answers a result with `isError: true`,
  not a success.
- Test: `MCPRequestProcessorTest >> testUnknownToolIsProtocolError` — pins the other half
  of the rule: finding the tool is a protocol error, `-32602`.
- Change: `MCPTool >> missingRequiredArgumentsIn:` reading `required` from the tool's own
  `inputSchema`; `handleToolsCall:id:` answers a tool error when the list is not empty.
  The specification moved input validation to tool errors so the model can correct itself
  (SEP-1303).
- Done when: both tests pass and no handler block carries its own `'Error: missing …'`
  string any more.

### 2.5 Truncation limit

- Test: `MCPRequestProcessorTest >> testLongResultIsTruncatedWithItsSizeStated` — a result
  longer than the limit ends in a note naming the original character count.
- Change: `MCPRequestProcessor class >> maximumResultSize`; the note says how much was cut.
- Done when: the test passes and `10000` appears in no method body.

### 2.6 `instructions` and `serverInfo`

- Test: `MCPRequestProcessorTest >> testInitializeCarriesInstructions` — the result holds a
  non-empty `instructions` string.
- Test: `MCPRequestProcessorTest >> testServerInfoCarriesNameAndVersion`.
- Change: `instructions` from a class-side method naming this project's own conventions
  (the image is the source of truth, CR line endings, run the critics, write the failing
  test first); `serverInfo` version read from the baseline rather than written as `'1.0.0'`.
- Done when: both tests pass.

---

## Phase 3 — Tool metadata a modern client reads

### 3.1 `MCPTool` carries title, annotations and output schema

- Test: `MCPToolTest >> testAsDictionaryOmitsAbsentOptionalFields` — a tool built the old
  way emits exactly `name`, `description`, `inputSchema`.
- Test: `MCPToolTest >> testAsDictionaryCarriesTitleAndAnnotations`.
- Change: instance variables `title`, `annotations`, `outputSchema` with accessors, emitted
  only when set, so every existing construction keeps working.
- Done when: both tests pass and the 22 existing tools still list unchanged.

### 3.2 Annotate the 22 tools

- Test: `MCPPharoToolsTest >> testReadOnlyToolsAreAnnotatedReadOnly` — the browsing tools
  answer `readOnlyHint: true`.
- Test: `MCPPharoToolsTest >> testDestructiveToolsAreAnnotatedDestructive` —
  `class_remove`, `package_remove`, `delete_method`.
- Test: `MCPPharoToolsTest >> testEveryToolIsAnnotated` — none is left to the
  specification's defaults, which are `destructiveHint: true` and `openWorldHint: true`.
- Change: annotations on each factory method, plus a `title` for each; `openWorldHint` is
  false everywhere, since every tool acts on the local image.
- Done when: the three tests pass.

### 3.3 Structured results for the two tools that have a shape

- Test: `MCPPharoToolsRunningTest >> testRunTestsAnswersStructuredContent` — the result
  carries counts as data beside the text block.
- Test: `MCPPharoToolsRunningTest >> testRunCriticsAnswersStructuredContent`.
- Change: `outputSchema` on both tools and `structuredContent` in the result; the
  serialised JSON stays in the text block, as the specification recommends.
- Done when: both tests pass and the schemas validate the structures the tools emit.

---

## Phase 4 — Standards sweep

### 4.1 `PharoMCP-Examples`

- Test: `MCPConventionTest >> testEveryExampleIsClassSideUnaryAndTagged`.
- Change: a new package holding one `<Subject>Examples` class per subject, each with a
  class comment: `MCPServerExamples` (the three methods now on `MCPExample`, renamed
  without the prefix), `MCPToolExamples`, `MCPLoggerExamples`, `MCPLogEntryExamples`,
  `MCPRequestProcessorExamples`. The window opener is named `openServerWindow`.
- Done when: the test passes, `MCPExample` is gone, and each example rebuilds its object on
  every call.
- **Done.** `PharoMCP-Examples` holds `MCPServerExamples` (the server lifecycle entry points
  moved off `MCPExample`, plus `openServerWindow`), `MCPToolExamples`,
  `MCPRequestProcessorExamples`, `MCPLoggerExamples` and `MCPLogEntryExamples`, each with a
  class comment. `MCPExample` was verified unreferenced and removed.
  `MCPConventionTest >> testEveryExampleIsClassSideUnaryAndTagged` and
  `testEveryExampleRebuildsItsObject` hold the shape; the second is also what references the
  example classes, so `ReClassNotReferencedRule` stays quiet without a registry method.

### 4.2 Test package tags and comments

- Change: a `Tests` tag and a `Fixtures` tag in `PharoMCP-Tests`; the ten test classes with
  no class comment get one; `MCPRecordingTextPresenterStub` moves to `Fixtures`.
- Done when: `run_critics` on `PharoMCP-Tests` reports no `ReClassNotCategorizedRule` and
  no class is left without a comment.
- **Done.** Tags `Tests` and `Fixtures` exist, every test class sits in `Tests` and
  `MCPRecordingTextPresenterStub` in `Fixtures`, and the ten missing class comments are
  written. `MCPConventionTest >> testEveryClassCarriesACommentWithoutLineFeeds` holds all
  three packages to it. Giving `MCPPharoToolsRunningTest` a comment broke
  `testGetClassCommentNoComment`, which had used that class as its commentless subject; the
  test now installs and removes a throwaway class instead.

### 4.3 Baseline groups

- Test: `MCPConventionTest >> testBaselineDeclaresTheExpectedGroups`.
- Change: `default`, `tests`, `examples` and `dev` (MuTalk) groups in
  `BaselineOfPharoMCP`, and the examples package declared.
- Done when: the test passes and `Metacello … load: 'default'` loads no test package.
- **Done.** The baseline declares `PharoMCP-Examples` and the four groups. `default` is the
  server package alone, held by `testDefaultGroupLoadsNoTestPackage`; `PharoMCP-Tests`
  requires the examples package, because the test classes read the examples, so `tests` loads
  both. `dev` adds MuTalk pinned to tag `v3.0.8`, not `master`, so a mutation score measured
  today can be measured again against the same mutant operators. The examples package was
  also missing from the Iceberg working copy, so 4.1 had committed none of its source; adding
  it is part of the same commit.

### 4.4 Convention meta tests

- Change: `MCPConventionTest` holds the project to its own rules — class comments with no
  LF, every `<sampleInstance>` example class-side and unary, every inspector view a keyword
  selector taking the builder, and the protocol revision strings confined to the constants
  method.
- Done when: the class is green and fails when any rule is broken on purpose.
- **Done.** Seven tests: class comments present and free of line feeds, examples class-side
  and unary and in the examples package, examples rebuilding their object on every call,
  inspector views keyword selectors taking the builder, revision strings confined to
  `supportedProtocolVersions` and `assumedProtocolVersion`, and the baseline's packages and
  groups. Each rule was broken on purpose and seen to fail: a line feed in a class comment, a
  keyword `<sampleInstance>` method, a unary inspector view, and a revision string written
  inline; all four were reverted and the class is green again. The rebuild test is also what
  references the five example classes, so `ReClassNotReferencedRule` is quiet without a
  registry method.

### 4.5 Inspector views where they pay

- Test: `MCPConventionTest >> testInspectorViewsTakeTheBuilder` (shared with 4.4).
- Change: a tool table on `MCPPharoTools class` showing name, title and annotations; a view
  on `MCPTestResult`; a class-side view on `MCPLogEntry` gated on position in the hierarchy,
  explaining how a request maps to an entry subclass.
- Done when: each view opens on its example without mutating the inspected object.
- **Done.** `MCPPharoTools class >> inspectorToolTable:` lists the 22 tools with title, hints
  and whether an output schema is set, reading the hints off each tool rather than restating
  them. `MCPTestResult >> inspectorOutcome:` shows the counts and the first failure and error
  message. `MCPLogEntry class >> inspectorRequestMapping:` explains which request reaches
  which entry subclass, gated by `inspectorRequestMappingContext:` on being the root of the
  hierarchy, and each row asks `MCPLogger` the real question through a synthesised request.
  Two tests in `MCPConventionTest` hold all nine views: each builds on the example an
  inspector would show, and none changes its subject, compared on a fingerprint of
  `printString` plus the size of the collections a view could add to.
  `MCPPharoToolsExamples` is the new examples class they read.

### 4.6 Critics clean

- Change: `self` in place of the class name in the 20 `MCPPharoTools class` methods;
  explicit returns in `MCPLogger >> clear` and `MCPNullLogger >> clear`; the log entry
  subclasses referenced from a registry method so `ReClassNotReferencedRule` goes quiet
  without deleting anything.
- Done when: `run_critics` on both packages is empty except for findings this plan
  deliberately leaves to Phase 5.
- **Done.** `self` in place of the class name in 14 class-side factories, 56 findings gone;
  explicit `^ self` in both `clear` methods; `MCPLogEntry class >> entryClasses` names the
  fourteen entry subclasses, and the logger and the new view read it instead of
  `allSubclasses`, which is what makes the five unreferenced subclasses referenced;
  `testWorldMenuOffersTheServerWindow` is the reference `MCPMenus` lacked, since the
  `<worldMenu>` pragma is its only caller. Fixing the class-name references uncovered a real
  defect: `testCompileMethodNormalisesLF` carried its line feed in a string literal, which
  both the editor and the MCP compile path normalise to CR, so the test had stopped testing
  LF; it now builds the separator from `Character lf`. What is left is 22
  cyclomatic-complexity, 14 long-method and two excessive-methods findings, all on the
  `MCPPharoTools` factories and their running test, which is Phase 6's subject.

---

## Phase 5 — Capabilities worth adding

Each is optional in the specification. Order is by value to a Pharo client.

### 5.1 `completions`

- Test: `MCPRequestProcessorTest >> testCompletionAnswersClassNames`.
- Change: a `completion/complete` branch and the `completions` capability; completion over
  class names, selectors and package names, which the image answers immediately.
- Done when: a prefix answers a bounded, sorted list and the capability is declared.
- **Done.** Three sources keyed by resource-URI prefix — `pharo://class/`,
  `pharo://package/`, `pharo://selector/` — each a block in
  `MCPRequestProcessor class >> completionSources`, evaluated on demand because the selector
  table holds some ninety thousand symbols and a held copy would go stale on the next
  compile. The answer is sorted, capped at the hundred values the specification allows, and
  says how many names matched and whether more exist; an unknown reference answers an empty
  completion rather than an error. Six tests, the example `completionResponse`, the view
  `inspectionCompletion:`. `dispatchRequest:` had grown a fifth equality test, so the
  branches moved into `handlerSelectors` and the method performs what it finds there;
  `handlePing:` became `handlePing:id:` so every handler has one shape.

### 5.2 `resources`

- Test: `MCPRequestProcessorTest >> testResourcesListCarriesClassesAndPackages`.
- Change: `resources/list` and `resources/read` over `pharo://class/<Name>` and
  `pharo://package/<Name>`; the `resources` capability.
- Done when: a client can read a class's source without spending a tool call.
- **Done.** `resources/read` over `pharo://class/<Name>` answers the definition, the class
  comment and the source of every instance-side and class-side method; over
  `pharo://package/<Name>` it answers each class of the package with its comment. Both kinds
  live in `MCPRequestProcessor class >> resourceSources`, one entry carrying the template
  parameter, the name, the description and the reader block, so a kind cannot be offered as
  a template and then answer nothing when read; `resources/templates/list` is built from
  that table. Deviation from this unit as written: `resources/list` answers one resource per
  package and no class at all, because the image holds fifteen thousand classes and a list
  of them is neither readable nor useful — a class is reached through its template, so the
  test is `testResourcesListCarriesEveryPackage` and the classes are held by
  `testResourceTemplatesCarryClassesAndPackages`. A URI no source claims, and a name no
  source holds, both answer -32002. Seven tests, the example `resourceReadResponse`, the
  view `inspectionResources:`. `completionSources` now keys off the same prefix constants,
  so the two features cannot drift apart on a spelling.

### 5.3 `prompts`

- Test: `MCPRequestProcessorTest >> testPromptsListCarriesTheCycle`.
- Change: `prompts/list` and `prompts/get`, carrying this image's own workflows: the red,
  green, refactor, example, view cycle; the bug workflow; the design review.
- Done when: the two methods answer and the capability is declared.
- **Done.** `red_green_refactor`, `bug_workflow` and `design_review`, each in
  `MCPRequestProcessor class >> promptTemplates` with its title, description, arguments and
  template, and each template's text in a method of its own so it reads as prose. Every
  argument carries a placeholder, which is what the text reads when the client leaves it
  out, so a prompt asked for with no arguments is still readable and shows no brace to the
  model that follows it; the arguments are therefore declared not required.
  `testPromptArgumentsAreDeclaredAndSubstituted` holds the two halves to each other. An
  unknown name answers -32602. Five tests, the example `promptGetResponse`, the view
  `inspectionPrompts:`. Suite: 307 tests, all green.

### Deferred

A GET endpoint with an SSE stream, and with it `logging`, progress notifications and
`notifications/tools/list_changed`, is the one structural gap. It needs a second delegate
path and a stream registry, so it gets its own plan rather than a unit here. Returning 405
on GET is allowed by the specification, so nothing is broken meanwhile.

Tasks (`execution.taskSupport`) stay out: they are experimental in 2025-11-25.

---

## Phase 6 — Design review of `MCPPharoTools`

`MCPPharoTools` holds 52 class-side methods, all 22 tool factories, their schemas and
their handler blocks. The critics report four long methods and six with high cyclomatic
complexity. The honest fix is one class per tool with `name`, `description`, `inputSchema`,
`annotations` and `execute:` as methods, which also makes per-tool tests and the Phase 3
metadata cheap.

That is a refactor of the whole package, so it follows the project's rule: diagnose, name
the refactoring for each point, prioritise by gain against risk, present the plan and wait
for validation before any edit. Nothing in this phase is started before phases 1 to 4 are
green and committed.

### The units, as approved

The diagnosis listed six points. Points 1, 2, 3, 4 and 6 were approved and are recorded here.
Point 5 was declined and is recorded as not done, so a later reader does not take it for
an oversight.

### 6.1 A tool that fails reports success

- Test: `MCPRequestProcessorTest >> testEveryToolSaysSoWhenItFails`, written first and seen
  to fail — a handler that returned a text starting with `Error` answered `isError: false`.
- Change: signal an error instead of returning its text.
- Done when: a failing call over `tools/call` answers `isError: true` and the text a client
  reads is unchanged.
- **Done**, commit `1548ddc`. The helpers and the handler blocks signal `MCPToolError`, a new
  `Error` subclass in the `Core` tag, with the bare reason; the processor already caught
  `Error` and wrote the `Error: ` prefix, so only the flag changed. `evaluate_pharo` lost its
  own handler for the same reason. The 42 tests that asserted the literal prefix on a helper
  return now use `should:raise:withExceptionDo:` and check the reason. `MCPToolError` carries
  its example and an inspector view built through the processor, so the view cannot drift from
  what a client sees. 308 tests pass.

### 6.2 The dead required-argument guards

- Test: `MCPRequestProcessorTest >> testEveryRequiredArgumentIsRejectedBeforeTheHandlerRuns`,
  which pins the processor guard for every registered tool before anything is removed.
- Change: remove the guard repeated inside fourteen handler blocks.
- Done when: the suite is green with the guards gone.
- **Done**, commit `e983857`. `handleToolsCall:id:` asks the tool which required arguments the
  call did not carry and answers a tool error before the handler runs, so the repeated check
  was unreachable. Five tests in `MCPPharoToolsExtendedTest` called a handler block with an
  empty dictionary and only the dead guard made them pass; they now go through `tools/call` by
  `missingArgumentTextOf:args:`. 309 tests pass. Critics on `MCPPharoTools` fall from 36 to 17.

### 6.3 One class lookup, one package lookup

- Change: extract the duplicated `Smalltalk globals at: ... ifAbsent:` lookup, its not-found
  text and the metaclass switch on the side argument.
- Done when: no helper writes the lookup itself and every not-found text is unchanged.
- **Done**, commit `af5a925`. `classNamed:as:side:` holds the lookup, the failure and the side
  once; the role argument names what the name stood for in the call, so `class not found`,
  `superclass not found` and `source class not found` stay the texts they were.
  `classNamed:`, `classNamed:as:` and `classNamed:side:` delegate to it and `packageNamed:`
  does the same for a package. Three handler blocks that kept their body where the lookup was
  gave it up to `listMethodsOn:side:` and `methodSourceOf:onClass:side:`. 309 tests pass.
  Critics fall from 17 to 11.

### 6.4 The schema boilerplate

- Change: extract the JSON Schema shape every factory wrote by hand.
- Done when: a factory names only what differs between it and the next one.
- **Done**, commit `2014bd8`. `schemaWithProperties:required:` states the object shape once and
  takes the properties as associations; `schemaPropertyOneOf:describedAs:` builds an enum
  property and `schemaSideProperty` is the side argument itself, described once — the six tools
  that each described it differently now say the same thing about it, which is what they always
  meant. The handlers that read an optional argument into a temporary only to test it for nil
  now use `ifNotNil:` with the argument. 309 tests pass. Critics stay at 11: what is left is
  the conditional inside four handler blocks, which point 6 dissolves.

### 6.5 `className` against `class_name` — not done

The tools disagree on the spelling of the class argument: `class_name` in sixteen of them,
`className` in `list_methods`, `method_source` and `class_definition`. Renaming either way is
a break in the published tool surface, so the point was declined. The inconsistency stands and
is deliberate.

### 6.6 One class per tool

- Test: `MCPPharoToolsTest >> testEveryToolIsItsOwnClass`, which holds every tool in
  `allTools` to being an `MCPTool` subclass carrying no handler block.
- Change: 22 `MCPTool` subclasses with `name`, `description`, `inputSchema`, `annotations` and
  `execute:` as methods, migrated one tool at a time with the suite green.
- Done when: the meta test passes and the factories answer instances.
- **Done**, commits `f14a4b4` (the groundwork) and the migration commit that follows it.
  `MCPTool >> call:`, which is all the request processor sends, answers by sending `execute:`;
  a subclass overrides `execute:` and the tools built from a block answer through the block in
  `MCPTool >> execute:` itself, so a client-registered tool still works. The schema builders
  moved to `MCPTool`, where a tool class reaches them as `self`, and `readOnlyHints`,
  `additiveHints` and `destructiveHints` answer the annotation dictionary a tool class returns
  from `annotations`. `MCPTool` had to stop reading its own slots and send its accessors
  instead: `missingRequiredArgumentsIn:`, `asDictionary`, `answersStructuredContent:` and
  `inspectionSchema:` read nil slots on a subclass otherwise. The 22 factory selectors survive
  and answer instances, because the running tests send them. The twenty-two new classes carry
  the `Tools` tag. `testReportSchema`, `critiqueReportSchema` and the schema builders left on
  `MCPPharoTools class` are deleted, the two output schemas now being methods of
  `MCPRunTestsTool` and `MCPRunCriticsTool`. Three tests in `MCPPharoToolsRunningTest` sent
  `tool handler value:`, which pinned the tool being a block holder rather than any fact about
  `list_methods`; reported before the change and then sent `tool call:` instead, assertions
  untouched. 310 tests pass. Critics on `MCPPharoTools` fall from 11 to 3 and on the whole
  `PharoMCP` package to the same 3: the method count on `MCPPharoTools class` and the
  complexity of `searchSource:inMethods:caseSensitive:` and `listPackagesMatching:`, which are
  helpers, not tool plumbing.

## Phase 7 — what Phase 6 left behind

Four leftovers were named after Phase 6 and taken in order. A fifth, the GET endpoint with an
SSE stream, stays open and is not part of this phase.

### 7.1 The documents that still described the old shape

`README.md` said the project requires Pharo 10 or 11. It was developed on Pharo 13 and runs on
Pharo 14 builds, and the inspector views need the presenter builder Pharo 13 introduced, so both
places now say Pharo 13 or later. Option C told a reader to file in four `.class.st` files by
hand; every tool is a class of its own now, so that leaves an image which cannot answer
`tools/list`. Option C says to use the baseline instead. `CLAUDE.md` describes `MCPTool` as the
superclass of the twenty-two tool classes in the `Tools` tag, `MCPPharoTools` as the factories
and the helpers, and names all three steps for adding a tool. **Done**, commit `446d2fc`.

### 7.2 What MuTalk says about the tool classes

The checkout was clean first, and `classesToMutate` held `MCPTool` and its twenty-two subclasses
and nothing else. Before the new tests: 659 mutants on `MCPTool`, score 36; 2128 mutants on the
tool classes, score 36. The alive mutants sat in `inputSchema` (455), `outputSchema` (409),
`execute:` (280), `critiqueArraySchema` (152), `title` and `description` (44 each) and `name`
(6) — the declared surface was almost entirely unpinned. After 7.3: 43 for `MCPTool` and 62 for
the tool classes. What stays alive is description prose, which only a copy of the text in a test
would kill, and the error branches of `execute:` that the running tests already reach by another
route. **Done.**

A mutation run leaves the image dirty when a mutant kills a test in the middle of its body: both
`TestCreateMCPXYZ` and `MCPSandboxPlain` were found afterwards, the second moved to the
unpackaged package by its own tearDown. Checked after each run and removed; the working copy is
clean. `MCPToolArgumentDefaultsTest >> tearDown` now also removes anything left under its own
class-name prefix, because removing a package moves a class it still holds instead of deleting
it.

### 7.3 The tests one class per tool was supposed to make cheap

- Test: `MCPToolSurfaceTest`, 16 tests over a written-out table of the published surface, and
  `MCPToolArgumentDefaultsTest`, 15 tests that call each tool through `call:` for the arguments
  the schema marks optional.
- Done when: both pass, the suite passes, critics are clean on both, and the mutation score
  rises.
- **Done**, commit `d30b2c7`. The surface table is written out rather than read from the tools:
  a difference between it and the image is a change every client sees, which is the whole point
  of pinning it. It holds each tool name, its required and optional arguments, the keys of the
  structured answer the two reporting tools give and the rows inside those arrays, plus the
  shape of a tool class — an `execute:` of its own, a title that is not the name, the four
  annotation hints, and the `Tools` tag. The defaults test pins what a missing optional argument
  means: the instance side in all six tools that take `side`, `Object` and no instance variables
  for a new class, `as yet unclassified` for a compiled method, a case-insensitive search, and
  `package` winning over `class_name` in `search_source`, which signals when it gets neither. It
  builds a scratch package in `setUp` and removes it in `tearDown`, so nothing it creates
  reaches a repository package. 341 tests pass.

### 7.4 An example and a view for the tool classes

- Change: `MCPTool class >> inspectorToolClasses:`, a Tool classes table with one row per
  subclass — its tool name, its required arguments, whether it answers its own `execute:` and
  whether it declares an output schema — and `MCPToolExamples class >> toolWithAlternativeArguments`,
  which answers `search_source`, the one tool whose `execute:` branches.
- Done when: `MCPConventionTest` holds the new view like every other, with `MCPTool class`
  registered as a subject.
- **Done**, commit `d30b2c7`. Twenty-two `<Subject>Examples` classes and twenty-two views were
  considered and refused: each tool class would get an example that only calls the factory and a
  view identical to the two `MCPTool` already declares, which is noise, not documentation. The
  family view on the class side is what a reader of this hierarchy actually wants, and it is
  where the project keeps a view that explains a rule the whole hierarchy follows. Every row is
  read off the class itself, so a tool class that forgets one of them shows an empty cell rather
  than a wrong one.
