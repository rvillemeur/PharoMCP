"
HTTP server that exposes the Pharo image as an MCP (Model Context Protocol) endpoint.

Owns a ZnServer and acts as its delegate, routing JSON-RPC 2.0 POST requests to an MCPRequestProcessor. Implements both Zinc delegate protocols for compatibility:
- handleRequest: aRequest  (functional, returns ZnResponse)
- handleRequest: aRequest into: aResponse  (service, modifies in place)

Usage:
    | s |
    s := MCPServer onPort: 7777.
    s start.
    Smalltalk at: #PharoMCPServer put: s.

Key methods:
- default / onPort:     creation
- start / stop          lifecycle
- registerTool:         add custom MCPTool at runtime
- processor             access the MCPRequestProcessor
"
Class {
	#name : 'MCPServer',
	#superclass : 'Object',
	#instVars : [
		'httpServer',
		'port',
		'processor',
		'announcer',
		'logger',
		'bindingAddress',
		'token'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPServer class >> allowedOriginPrefixes [

	"A browser page can POST to this server from any site, and the server evaluates arbitrary
	 Pharo code, so a request carrying a foreign Origin is a cross-site attack and is refused.
	 The MCP specification makes this validation a MUST for a local HTTP server. A request with
	 no Origin header at all is not browser-driven and is served: that is how the command-line
	 client reaches the image."

	^ #( 'http://localhost' 'http://127.0.0.1' 'http://[::1]' )
]

{ #category : 'accessing' }
MCPServer class >> assumedProtocolVersion [

	"The specification says a request with no MCP-Protocol-Version header is to be read as this
	 revision, the last one that did not require the header."

	^ '2025-03-26'
]

{ #category : 'accessing' }
MCPServer class >> authorizationHeaderName [

	^ 'Authorization'
]

{ #category : 'accessing' }
MCPServer class >> bearerPrefix [

	^ 'Bearer '
]

{ #category : 'instance creation' }
MCPServer class >> current [
	^ Smalltalk at: #PharoMCPServer ifAbsentPut: [ self default ]
]

{ #category : 'instance creation' }
MCPServer class >> default [

	^ self onPort: self defaultPort
]

{ #category : 'accessing' }
MCPServer class >> defaultPort [

	"The port the README, the examples and ~/.claude.json all name."

	^ 7777
]

{ #category : 'accessing' }
MCPServer class >> loopbackAddress [

	"The MCP specification says a local HTTP server SHOULD bind to 127.0.0.1 only. This image
	 cannot make that the default: the command-line client runs in a container and reaches the
	 image through host.docker.internal, which is not the loopback interface. An image serving
	 only clients on this machine sends bindLoopbackOnly before start."

	^ #[ 127 0 0 1 ]
]

{ #category : 'instance creation' }
MCPServer class >> onPort: aPort [
	^ self new
		port: aPort;
		yourself
]

{ #category : 'accessing' }
MCPServer class >> protocolVersionHeaderName [

	^ 'MCP-Protocol-Version'
]

{ #category : 'private' }
MCPServer >> addCorsHeadersTo: aResponse [

	^ self addCorsHeadersTo: aResponse origin: nil
]

{ #category : 'private' }
MCPServer >> addCorsHeadersTo: aResponse origin: anOriginOrNil [

	"Echo the request's own origin rather than '*' when there is one: a wildcard tells every
	 browser page that its scripted requests may read this server's answers."

	aResponse headers
		at: 'Access-Control-Allow-Origin' put: (anOriginOrNil ifNil: [ '*' ]);
		at: 'Access-Control-Allow-Methods' put: 'POST, OPTIONS';
		at: 'Access-Control-Allow-Headers' put: 'Content-Type, Accept'.
	^ aResponse
]

{ #category : 'accessing' }
MCPServer >> announcer [
	^ announcer
]

{ #category : 'private' }
MCPServer >> badRequestResponse [

	^ ZnResponse new
		statusLine: ZnStatusLine badRequest;
		entity: (ZnEntity text: 'Unsupported ' , self class protocolVersionHeaderName);
		yourself
]

{ #category : 'accessing' }
MCPServer >> bindLoopbackOnly [

	^ self bindingAddress: self class loopbackAddress
]

{ #category : 'accessing' }
MCPServer >> bindingAddress [

	^ bindingAddress
]

{ #category : 'accessing' }
MCPServer >> bindingAddress: aByteArrayOrNil [

	"nil binds every interface, which is what an image reached from a container needs."

	bindingAddress := aByteArrayOrNil
]

{ #category : 'accessing' }
MCPServer >> bindingDescription [

	^ bindingAddress
		ifNil: [ 'every interface' ]
		ifNotNil: [ :address | '.' join: (address asArray collect: [ :each | each printString ]) ]
]

{ #category : 'private' }
MCPServer >> buildResponseFor: result [
        "Notifications (nil result) get 202 Accepted with explicit empty body, per MCP Streamable HTTP.
        Without Content-Length the keep-alive client waits forever for a body."
        | response |
        result ifNotNil: [
                ^ self addCorsHeadersTo: (ZnResponse ok: (ZnEntity
                        with: result
                        type: ZnMimeType applicationJson)) ].
        response := ZnResponse new.
        response statusLine: (ZnStatusLine code: 202).
        response headers at: 'Content-Length' put: '0'.
        ^ self addCorsHeadersTo: response
]

{ #category : 'private' }
MCPServer >> extractBodyFrom: request [
	^ (request hasEntity and: [ request entity notNil ])
		ifTrue: [ request entity string ]
		ifFalse: [ '{}' ]
]

{ #category : 'private' }
MCPServer >> forbiddenResponse [

	^ ZnResponse new
		statusLine: (ZnStatusLine code: 403);
		entity: (ZnEntity text: 'Forbidden');
		yourself
]

{ #category : 'private' }
MCPServer >> handleNonPostRequest [
	^ self addCorsHeadersTo: (ZnResponse new
		statusLine: ZnStatusLine methodNotAllowed;
		entity: (ZnEntity text: 'Method Not Allowed');
		yourself)
]

{ #category : 'private' }
MCPServer >> handleOptionsRequest [
        | response |
        response := ZnResponse new.
        response statusLine: ZnStatusLine ok.
        response headers at: 'Content-Length' put: '0'.
        ^ self addCorsHeadersTo: response
]

{ #category : 'handling' }
MCPServer >> handleRequest: request [
	"Functional delegate protocol — ZnServer uses the returned ZnResponse"

	| origin body result |
	(self rejectionFor: request) ifNotNil: [ :rejection | ^ rejection ].
	origin := self originOf: request.
	request method = 'OPTIONS' ifTrue: [
		^ self addCorsHeadersTo: self handleOptionsRequest origin: origin ].
	request method ~= 'POST' ifTrue: [
		^ self addCorsHeadersTo: self handleNonPostRequest origin: origin ].
	body := self extractBodyFrom: request.
	result := self safeProcess: body.
	self logRequest: body response: result.
	^ self addCorsHeadersTo: (self buildResponseFor: result) origin: origin
]

{ #category : 'handling' }
MCPServer >> handleRequest: request into: response [
	"Service delegate protocol — ZnServer passes response to modify in place"

	| built |
	built := self handleRequest: request.
	response statusLine: built statusLine.
	built headers keysAndValuesDo: [ :key :value | response headers at: key put: value ].
	built entity ifNotNil: [ :e | response entity: e ]
]

{ #category : 'initialization' }
MCPServer >> initialize [

	super initialize.
	port := 7777.
	processor := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: processor.
	announcer := Announcer new.
	logger := MCPNullLogger new
]

{ #category : 'inspector' }
MCPServer >> inspectionStatus: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Status'>

	^ (StSimpleInspectorBuilder on: aBuilder)
		key: 'Port' value: port printString;
		key: 'Running' value: self isRunning printString;
		key: 'Tools' value: (processor ifNil: [ '0' ] ifNotNil: [ :p | p tools size printString ]);
		key: 'Logger' value: logger class name;
		key: 'Binding' value: self bindingDescription;
		key: 'Allowed origins' value: (', ' join: self class allowedOriginPrefixes);
		key: 'Foreign origin' value: (self isOriginAllowed: 'https://evil.example') printString;
		key: 'Token required' value: token notNil printString;
		key: 'Request without credential' value: (self isAuthorized: ZnRequest empty) printString;
		key: 'Request without version header' value: (self isProtocolVersionAccepted: ZnRequest empty) printString;
		table
]

{ #category : 'inspector' }
MCPServer >> inspectionTools: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Tools'>
	^ processor
		ifNil: [ aBuilder newText text: '(server not started)'; yourself ]
		ifNotNil: [ :p | p inspectionTools: aBuilder ]
]

{ #category : 'private' }
MCPServer >> isAuthorized: aRequest [

	| header |
	token ifNil: [ ^ true ].
	header := aRequest headers at: self class authorizationHeaderName ifAbsent: [ ^ false ].
	^ header = (self class bearerPrefix , token)
]

{ #category : 'testing' }
MCPServer >> isLogging [
	^ logger isActive
]

{ #category : 'private' }
MCPServer >> isOriginAllowed: anOriginOrNil [

	anOriginOrNil ifNil: [ ^ true ].
	^ self class allowedOriginPrefixes anySatisfy: [ :each | anOriginOrNil beginsWith: each ]
]

{ #category : 'private' }
MCPServer >> isProtocolVersionAccepted: aRequest [

	| version |
	version := aRequest headers
		at: self class protocolVersionHeaderName
		ifAbsent: [ self class assumedProtocolVersion ].
	^ MCPRequestProcessor supportedProtocolVersions includes: version
]

{ #category : 'testing' }
MCPServer >> isRunning [
	^ httpServer notNil and: [ httpServer isRunning ]
]

{ #category : 'private' }
MCPServer >> logRequest: body response: result [
	[ | entry |
	  entry := logger log: body response: result.
	  entry ifNotNil: [
		announcer announce: (MCPRequestLogged new entry: entry; yourself) ] ]
		on: Error do: [ :e | Transcript show: 'MCPServer log error: ' << e messageText; cr ]
]

{ #category : 'accessing' }
MCPServer >> logger [
	^ logger
]

{ #category : 'private' }
MCPServer >> originOf: aRequest [

	^ aRequest headers at: 'Origin' ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPServer >> port [
	^ port
]

{ #category : 'accessing' }
MCPServer >> port: anInteger [
	port := anInteger
]

{ #category : 'accessing' }
MCPServer >> processor [
	^ processor
]

{ #category : 'tool management' }
MCPServer >> registerTool: aTool [
	processor registerTool: aTool
]

{ #category : 'private' }
MCPServer >> rejectionFor: aRequest [

	"nil when the request passes every gate the specification asks a local server to keep."

	(self isOriginAllowed: (self originOf: aRequest)) ifFalse: [ ^ self forbiddenResponse ].
	(self isAuthorized: aRequest) ifFalse: [ ^ self unauthorizedResponse ].
	(self isProtocolVersionAccepted: aRequest) ifFalse: [ ^ self badRequestResponse ].
	^ nil
]

{ #category : 'accessing' }
MCPServer >> requireToken: aStringOrNil [

	"The MCP specification says a local HTTP server SHOULD authenticate its clients. nil, the
	 default, requires nothing, because the client this image serves today sends no credential.
	 The comparison below is a plain string equality: this endpoint answers one client on one
	 machine, so a timing side channel buys an attacker who can already reach the socket nothing."

	token := aStringOrNil
]

{ #category : 'private' }
MCPServer >> safeProcess: body [
	^ [ processor processRawRequest: body ]
		on: Error
		do: [ :e |
			NeoJSONWriter toString: (Dictionary new
				at: 'jsonrpc' put: '2.0';
				at: 'id' put: nil;
				at: 'error' put: (Dictionary new
					at: 'code' put: -32603;
					at: 'message' put: 'Internal error: ' , e messageText;
					yourself);
				yourself) ]
]

{ #category : 'running' }
MCPServer >> start [

	"Register before the running check, so a start sent to an already running server still
	 names it as the current one: the window and every other reader resolve the server
	 through #PharoMCPServer, and a server that runs unregistered reads as stopped."

	Smalltalk at: #PharoMCPServer put: self.
	self isRunning ifTrue: [ ^ self ].
	httpServer := ZnServer on: port.
	bindingAddress ifNotNil: [ :address | httpServer bindingAddress: address ].
	httpServer delegate: self.
	httpServer start.
	Transcript show: 'PharoMCP running on http://localhost:', port printString; cr.
	announcer announce: MCPServerStarted new
]

{ #category : 'logging' }
MCPServer >> startLogging [
	logger isActive ifTrue: [ ^ self ].
	logger := MCPLogger new.
	announcer announce: MCPLoggingStarted new
]

{ #category : 'running' }
MCPServer >> stop [

	| s |
	s := httpServer.
	httpServer := nil.
	s ifNotNil: [ s stop ].
	"Forget only our own registration: another server may have taken the name since."
	(Smalltalk at: #PharoMCPServer ifAbsent: [ nil ]) == self ifTrue: [
		Smalltalk globals removeKey: #PharoMCPServer ifAbsent: [ ] ].
	Transcript show: 'PharoMCP stopped'; cr.
	announcer announce: MCPServerStopped new
]

{ #category : 'logging' }
MCPServer >> stopLogging [
	logger isActive ifFalse: [ ^ self ].
	logger := MCPNullLogger new.
	announcer announce: MCPLoggingStopped new
]

{ #category : 'private' }
MCPServer >> unauthorizedResponse [

	^ ZnResponse new
		statusLine: (ZnStatusLine code: 401);
		headers: (ZnHeaders defaultResponseHeaders
			at: 'WWW-Authenticate' put: 'Bearer';
			yourself);
		entity: (ZnEntity text: 'Unauthorized');
		yourself
]
