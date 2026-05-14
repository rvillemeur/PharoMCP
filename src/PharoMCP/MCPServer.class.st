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
		'processor'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

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

{ #category : 'private' }
MCPServer >> handleRequest: request [
	"Functional delegate protocol — ZnServer uses the returned ZnResponse"
	| body result |

	request method = 'OPTIONS' ifTrue: [
		^ self addCorsHeadersTo: (ZnResponse new
			statusLine: ZnStatusLine ok;
			yourself) ].

	request method ~= 'POST' ifTrue: [
		^ self addCorsHeadersTo: (ZnResponse new
			statusLine: (ZnStatusLine code: 405 text: 'Method Not Allowed');
			entity: (ZnEntity text: 'Method Not Allowed');
			yourself) ].

	body := (request hasEntity and: [ request entity notNil ])
		ifTrue: [ request entity string ]
		ifFalse: [ '{}' ].

	result := [ processor processRawRequest: body ]
		on: Error
		do: [ :e |
			NeoJSONWriter toString: (Dictionary new
				at: 'jsonrpc' put: '2.0';
				at: 'id' put: nil;
				at: 'error' put: (Dictionary new
					at: 'code' put: -32603;
					at: 'message' put: 'Internal error: ' , e messageText;
					yourself);
				yourself) ].

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
	port := 7777.
	processor := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: processor
]

{ #category : 'testing' }
MCPServer >> isRunning [
	^ httpServer notNil and: [ httpServer isRunning ]
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

{ #category : 'control' }
MCPServer >> start [
	httpServer := ZnServer on: port.
	httpServer delegate: self.
	httpServer start.
	Transcript show: 'PharoMCP running on http://localhost:' , port printString; cr
]

{ #category : 'control' }
MCPServer >> stop [
	| s |
	s := httpServer.
	httpServer := nil.
	s ifNotNil: [ s stop ].
	Transcript show: 'PharoMCP stopped'; cr
]
