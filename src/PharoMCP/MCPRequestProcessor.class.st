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

{ #category : 'processing' }
MCPRequestProcessor >> dispatchRequest: request [
	| method id params |
	id := request at: 'id' ifAbsent: [ nil ].
	method := request at: 'method' ifAbsent: [
		^ self errorResponseWithId: id code: -32600 message: 'Invalid Request' ].
	params := request at: 'params' ifAbsent: [ Dictionary new ].

	"Notifications have no id — no response per JSON-RPC 2.0"
	(id isNil and: [ method beginsWith: 'notifications/' ]) ifTrue: [ ^ nil ].

	method = 'initialize' ifTrue: [ ^ self handleInitialize: params id: id ].
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

{ #category : 'handlers' }
MCPRequestProcessor >> handleInitialize: params id: id [
	^ self
		successResponseWithResult: (Dictionary new
			at: 'protocolVersion' put: '2024-11-05';
			at: 'capabilities' put: (Dictionary new
				at: 'tools' put: Dictionary new;
				yourself);
			at: 'serverInfo' put: (Dictionary new
				at: 'name' put: 'PharoMCP';
				at: 'version' put: '1.0.0';
				yourself);
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleToolsCall: params id: id [
	| toolName args tool resultText isError |
	toolName := params at: 'name' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: name' ].
	args := params at: 'arguments' ifAbsent: [ Dictionary new ].
	tool := tools at: toolName ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Tool not found: ' , toolName ].

	isError := false.
	resultText := [ tool call: args ]
		on: Error
		do: [ :e |
			isError := true.
			'Error: ' , e messageText ].

	resultText isString ifFalse: [ resultText := resultText printString ].
	resultText size > 10000 ifTrue: [
		resultText := (resultText copyFrom: 1 to: 10000) , '...(truncated)' ].

	^ self
		successResponseWithResult: (Dictionary new
			at: 'content' put: (Array with: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: resultText;
				yourself));
			at: 'isError' put: isError;
			yourself)
		id: id
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

{ #category : 'response building' }
MCPRequestProcessor >> successResponseWithResult: result id: id [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'result' put: result;
		yourself)
]

{ #category : 'accessing' }
MCPRequestProcessor >> tools [
	^ tools
]
