"
JSON-RPC 2.0 dispatcher for the MCP protocol.

Parses raw JSON strings, routes method calls to handlers, and manages a registry of MCPTool instances (keyed by name). Created and owned by MCPServer.

Supported methods:
- initialize       returns protocol version and server capabilities
- tools/list       returns all registered tool descriptors
- tools/call       invokes a named tool with arguments

Notifications (requests without an id) return nil — no response is sent, per JSON-RPC 2.0 spec. All errors are returned as JSON-RPC error response objects with standard codes (-32700 parse, -32600 invalid, -32601 not found, -32602 invalid params, -32603 internal).
"
Class {
	#name : 'MCPRequestProcessor',
	#superclass : 'Object',
	#instVars : [
		'tools'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> instructions [

	"Sent once, in the initialize result. A client reads it before it calls a tool, so it
	 states the rules of this image that a caller cannot discover from a tool schema."

	^ (String cr , String cr) join: #(
		'This server drives a live Pharo image. The image is the source of truth: change code through compile_method, class_create, delete_method and the other tools, never by writing a .class.st file.'
		'Pharo source uses CR line endings. A multi-line method body sent to compile_method must separate its lines with CR, never LF; an escape sequence is compiled as its own characters.'
		'Write the failing test before the code, run it with run_tests, and run run_critics on every class you change before you call the work done.'
		'evaluate_pharo answers the printString of the last expression. A result longer than the server''s maximum is truncated, and the note states how many characters it held.' )
]

{ #category : 'protocol versions' }
MCPRequestProcessor class >> latestProtocolVersion [

	^ self supportedProtocolVersions first
]

{ #category : 'accessing' }
MCPRequestProcessor class >> maximumResultSize [

	"Characters of a tool result the server sends before cutting it. A client pays for every
	 one of them in its context window, and a tool asked for too much is better corrected than
	 answered in full."

	^ 10000
]

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> serverName [

	"The name a client shows for this server, and the name the test reads rather than
	 repeating the literal."

	^ 'PharoMCP'
]

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> serverVersion [

	"Neither BaselineOfPharoMCP nor a Pharo package carries a version number, so this method
	 is the one place the server''s version is written. Raise it when the protocol surface or
	 the tool set changes, not on every commit."

	^ '1.1.0'
]

{ #category : 'protocol versions' }
MCPRequestProcessor class >> supportedProtocolVersions [

	"Newest first: the first entry is what a client that asks for nothing, or for a revision this
	 server does not know, is answered. 2024-11-05 stays in the list because clients still ask
	 for it and the specification requires the server to echo a revision it supports."

	^ #( '2025-11-25' '2025-06-18' '2025-03-26' '2024-11-05' )
]

{ #category : 'handling' }
MCPRequestProcessor >> dispatchRequest: request [

	| method id params |
	id := request at: 'id' ifAbsent: [ nil ].
	method := request at: 'method' ifAbsent: [
		^ self errorResponseWithId: id code: -32600 message: 'Invalid Request' ].
	params := request at: 'params' ifAbsent: [ Dictionary new ].
	"Notifications have no id — no response per JSON-RPC 2.0"
	(id isNil and: [ method beginsWith: 'notifications/' ]) ifTrue: [ ^ nil ].
	method = 'initialize' ifTrue: [ ^ self handleInitialize: params id: id ].
	method = 'ping' ifTrue: [ ^ self handlePing: id ].
	method = 'tools/list' ifTrue: [ ^ self handleToolsList: params id: id ].
	method = 'tools/call' ifTrue: [ ^ self handleToolsCall: params id: id ].
	^ self errorResponseWithId: id code: -32601 message: 'Method not found: ' , method
]

{ #category : 'response building' }
MCPRequestProcessor >> errorResponseWithId: id code: code message: msg [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'error' put: (Dictionary new
			at: 'code' put: code;
			at: 'message' put: msg;
			yourself);
		yourself)
]

{ #category : 'handling' }
MCPRequestProcessor >> handleInitialize: params id: id [

	^ self
		successResponseWithResult: (Dictionary new
			at: 'protocolVersion' put: (self negotiatedProtocolVersionFor: params);
			at: 'capabilities' put: (Dictionary new
				at: 'tools' put: Dictionary new;
				yourself);
			at: 'serverInfo' put: (Dictionary new
				at: 'name' put: self class serverName;
				at: 'version' put: self class serverVersion;
				yourself);
			at: 'instructions' put: self class instructions;
			yourself)
		id: id
]

{ #category : 'handling' }
MCPRequestProcessor >> handlePing: id [

	"A client that pings for liveness and gets an error back may treat the connection as dead,
	 so the specification makes an empty result a MUST here."

	^ self successResponseWithResult: Dictionary new id: id
]

{ #category : 'handling' }
MCPRequestProcessor >> handleToolsCall: params id: id [

	| toolName args tool missing |
	toolName := params at: 'name' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: name' ].
	args := params at: 'arguments' ifAbsent: [ Dictionary new ].
	tool := tools at: toolName ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Tool not found: ' , toolName ].
	missing := tool missingRequiredArgumentsIn: args.
	missing ifNotEmpty: [
		^ self toolErrorResult: (self missingArgumentsMessage: missing) id: id ].
	^ self resultOfCalling: tool with: args id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleToolsList: params id: id [
	| toolList |
	toolList := tools values collect: [ :t | t asDictionary ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'tools' put: toolList asArray;
			yourself)
		id: id
]

{ #category : 'initialization' }
MCPRequestProcessor >> initialize [

	super initialize.
	tools := Dictionary new
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionProtocol: aBuilder [

	<inspectorPresentationOrder: 2 title: 'Protocol'>

	| supported older unknown |
	supported := self class supportedProtocolVersions.
	older := supported last.
	unknown := 'no-such-revision'.
	^ (StSimpleInspectorBuilder on: aBuilder)
		key: 'Supported' value: (', ' join: supported);
		key: 'Latest' value: self class latestProtocolVersion;
		key: 'Client asks ' , older value: (self negotiatedProtocolVersionFor: (Dictionary with: 'protocolVersion' -> older));
		key: 'Client asks ' , unknown value: (self negotiatedProtocolVersionFor: (Dictionary with: 'protocolVersion' -> unknown));
		key: 'Client asks nothing' value: (self negotiatedProtocolVersionFor: Dictionary new);
		table
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionTools: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Tools'>
	| sorted |
	sorted := tools values asSortedCollection: [ :a :b | a name < b name ].
	^ aBuilder newTable
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :t | t name ]);
		addColumn: (SpStringTableColumn title: 'Description' evaluated: [ :t | t description truncateWithElipsisTo: 80 ]);
		items: sorted;
		yourself
]

{ #category : 'private' }
MCPRequestProcessor >> missingArgumentsMessage: aCollection [

	^ (aCollection size = 1
		ifTrue: [ 'Missing required argument: ' ]
		ifFalse: [ 'Missing required arguments: ' ]) , (', ' join: aCollection)
]

{ #category : 'private' }
MCPRequestProcessor >> negotiatedProtocolVersionFor: params [

	| requested |
	requested := params at: 'protocolVersion' ifAbsent: [ ^ self class latestProtocolVersion ].
	^ (self class supportedProtocolVersions includes: requested)
		ifTrue: [ requested ]
		ifFalse: [ self class latestProtocolVersion ]
]

{ #category : 'processing' }
MCPRequestProcessor >> processRawRequest: jsonString [
	| request |
	request := [ NeoJSONReader fromString: jsonString ]
		on: Error
		do: [ :e |
			^ self
				errorResponseWithId: nil
				code: -32700
				message: 'Parse error' ].
	(request isDictionary) ifFalse: [
		^ self errorResponseWithId: nil code: -32600 message: 'Invalid Request' ].
	^ self dispatchRequest: request
]

{ #category : 'tool management' }
MCPRequestProcessor >> registerTool: aTool [
	tools at: aTool name put: aTool
]

{ #category : 'private' }
MCPRequestProcessor >> resultOfCalling: aTool with: arguments id: id [

          | result isError |
          isError := false.
          result := [ aTool call: arguments ]
                  on: Error
                  do: [ :e |
                          isError := true.
                          'Error: ' , e messageText ].
          (isError not and: [ aTool answersStructuredContent: result ]) ifTrue: [
                  ^ self
                          toolResult: (self truncated: (NeoJSONWriter toStringPretty: result))
                          structured: result
                          id: id ].
          result isString ifFalse: [ result := result printString ].
          ^ self toolResult: (self truncated: result) isError: isError id: id
]

{ #category : 'response building' }
MCPRequestProcessor >> successResponseWithResult: result id: id [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'result' put: result;
		yourself)
]

{ #category : 'private' }
MCPRequestProcessor >> toolErrorResult: aString id: id [

	^ self toolResult: aString isError: true id: id
]

{ #category : 'private' }
MCPRequestProcessor >> toolResult: aString isError: aBoolean id: id [

	^ self
		successResponseWithResult: (Dictionary new
			at: 'content' put: (Array with: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: aString;
				yourself));
			at: 'isError' put: aBoolean;
			yourself)
		id: id
]

{ #category : 'private' }
MCPRequestProcessor >> toolResult: aString structured: aDictionary id: id [

	"A tool with an outputSchema answers its data in structuredContent, and the specification
	 asks for the same data serialised in the text block, for a client that reads only text."

	^ self
		successResponseWithResult: (Dictionary new
			at: 'content' put: { Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: aString;
				yourself };
			at: 'structuredContent' put: aDictionary;
			at: 'isError' put: false;
			yourself)
		id: id
]

{ #category : 'accessing' }
MCPRequestProcessor >> tools [
	^ tools
]

{ #category : 'private' }
MCPRequestProcessor >> truncated: aString [

	| limit |
	limit := self class maximumResultSize.
	aString size <= limit ifTrue: [ ^ aString ].
	^ (aString first: limit) , '...(truncated, ' , aString size printString , ' characters)'
]
