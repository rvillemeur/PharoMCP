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

### 4.4 Convention meta tests

- Change: `MCPConventionTest` holds the project to its own rules — class comments with no
  LF, every `<sampleInstance>` example class-side and unary, every inspector view a keyword
  selector taking the builder, and the protocol revision strings confined to the constants
  method.
- Done when: the class is green and fails when any rule is broken on purpose.

### 4.5 Inspector views where they pay

- Test: `MCPConventionTest >> testInspectorViewsTakeTheBuilder` (shared with 4.4).
- Change: a tool table on `MCPPharoTools class` showing name, title and annotations; a view
  on `MCPTestResult`; a class-side view on `MCPLogEntry` gated on position in the hierarchy,
  explaining how a request maps to an entry subclass.
- Done when: each view opens on its example without mutating the inspected object.

### 4.6 Critics clean

- Change: `self` in place of the class name in the 20 `MCPPharoTools class` methods;
  explicit returns in `MCPLogger >> clear` and `MCPNullLogger >> clear`; the log entry
  subclasses referenced from a registry method so `ReClassNotReferencedRule` goes quiet
  without deleting anything.
- Done when: `run_critics` on both packages is empty except for findings this plan
  deliberately leaves to Phase 5.

---

## Phase 5 — Capabilities worth adding

Each is optional in the specification. Order is by value to a Pharo client.

### 5.1 `completions`

- Test: `MCPRequestProcessorTest >> testCompletionAnswersClassNames`.
- Change: a `completion/complete` branch and the `completions` capability; completion over
  class names, selectors and package names, which the image answers immediately.
- Done when: a prefix answers a bounded, sorted list and the capability is declared.

### 5.2 `resources`

- Test: `MCPRequestProcessorTest >> testResourcesListCarriesClassesAndPackages`.
- Change: `resources/list` and `resources/read` over `pharo://class/<Name>` and
  `pharo://package/<Name>`; the `resources` capability.
- Done when: a client can read a class's source without spending a tool call.

### 5.3 `prompts`

- Test: `MCPRequestProcessorTest >> testPromptsListCarriesTheCycle`.
- Change: `prompts/list` and `prompts/get`, carrying this image's own workflows: the red,
  green, refactor, example, view cycle; the bug workflow; the design review.
- Done when: the two methods answer and the capability is declared.

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
