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
MCPServer >> handleRequest: request [
	"Functional delegate protocol (ZnServer returns this value)"
	| response |
	response := ZnResponse new.
	self handleRequest: request into: response.
	^ response
]

{ #category : 'private' }
MCPServer >> handleRequest: request into: response [
	"Service delegate protocol (ZnServer passes response to modify in place)"
	| body result |
	response headers
		at: 'Access-Control-Allow-Origin' put: '*';
		at: 'Access-Control-Allow-Methods' put: 'POST, OPTIONS';
		at: 'Access-Control-Allow-Headers' put: 'Content-Type, Accept'.

	request method = 'OPTIONS' ifTrue: [
		response status: 200.
		^ self ].

	request method ~= 'POST' ifTrue: [
		response status: 405.
		response entity: (ZnEntity text: 'Method Not Allowed').
		^ self ].

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

	result
		ifNil: [ response status: 200 ]
		ifNotNil: [
			response
				status: 200;
				entity: (ZnEntity
					with: result
					type: ZnMimeType applicationJson) ]
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
	Transcript show: 'PharoMCP running on http://localhost:' , port printString.
]

{ #category : 'control' }
MCPServer >> stop [
	| s |
	s := httpServer.
	httpServer := nil.
	s ifNotNil: [ s stop ].
	Transcript show: 'PharoMCP stopped'; nl
]
