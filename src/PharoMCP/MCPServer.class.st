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
		'logger'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'instance creation' }
MCPServer class >> current [
	^ Smalltalk at: #PharoMCPServer ifAbsentPut: [ self default ]
]

{ #category : 'instance creation' }
MCPServer class >> default [
	^ self onPort: 7777
]

{ #category : 'instance creation' }
MCPServer class >> onPort: aPort [
	^ self new
		port: aPort;
		yourself
]

{ #category : 'private' }
MCPServer >> addCorsHeadersTo: aResponse [
	aResponse headers
		at: 'Access-Control-Allow-Origin' put: '*';
		at: 'Access-Control-Allow-Methods' put: 'POST, OPTIONS';
		at: 'Access-Control-Allow-Headers' put: 'Content-Type, Accept'.
	^ aResponse
]

{ #category : 'accessing' }
MCPServer >> announcer [
	^ announcer
]

{ #category : 'private' }
MCPServer >> buildResponseFor: result [
	^ self addCorsHeadersTo: (result
		ifNil: [
			ZnResponse new
				statusLine: ZnStatusLine ok;
				yourself ]
		ifNotNil: [
			ZnResponse ok: (ZnEntity
				with: result
				type: ZnMimeType applicationJson) ])
]

{ #category : 'private' }
MCPServer >> extractBodyFrom: request [
	^ (request hasEntity and: [ request entity notNil ])
		ifTrue: [ request entity string ]
		ifFalse: [ '{}' ]
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
	^ self addCorsHeadersTo: (ZnResponse new
		statusLine: ZnStatusLine ok;
		yourself)
]

{ #category : 'private' }
MCPServer >> handleRequest: request [
	"Functional delegate protocol — ZnServer uses the returned ZnResponse"
	| body result |
	request method = 'OPTIONS' ifTrue: [ ^ self handleOptionsRequest ].
	request method ~= 'POST' ifTrue: [ ^ self handleNonPostRequest ].
	body := self extractBodyFrom: request.
	result := self safeProcess: body.
	self logRequest: body response: result.
	^ self buildResponseFor: result
]

{ #category : 'private' }
MCPServer >> handleRequest: request into: response [
	"Service delegate protocol — ZnServer passes response to modify in place"
	| built |
	built := self handleRequest: request.
	response statusLine: built statusLine.
	response headers
		at: 'Access-Control-Allow-Origin' put: '*';
		at: 'Access-Control-Allow-Methods' put: 'POST, OPTIONS';
		at: 'Access-Control-Allow-Headers' put: 'Content-Type, Accept'.
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

{ #category : 'testing' }
MCPServer >> isLogging [
	^ logger isActive
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
		on: Error do: [ :e | "absorb logging errors" ]
]

{ #category : 'accessing' }
MCPServer >> logger [
	^ logger
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

{ #category : 'control' }
MCPServer >> start [
	self isRunning ifTrue: [ ^ self ].
	httpServer := ZnServer on: port.
	httpServer delegate: self.
	httpServer start.
	Transcript show: 'PharoMCP running on http://localhost:',  port printString; cr.
	announcer announce: MCPServerStarted new
]

{ #category : 'logging' }
MCPServer >> startLogging [
	logger isActive ifTrue: [ ^ self ].
	logger := MCPLogger new.
	announcer announce: MCPLoggingStarted new
]

{ #category : 'control' }
MCPServer >> stop [
	| s |
	s := httpServer.
	httpServer := nil.
	s ifNotNil: [ s stop ].
	Transcript show: 'PharoMCP stopped'; cr.
	announcer announce: MCPServerStopped new
]

{ #category : 'logging' }
MCPServer >> stopLogging [
	logger isActive ifFalse: [ ^ self ].
	logger := MCPNullLogger new.
	announcer announce: MCPLoggingStopped new
]
