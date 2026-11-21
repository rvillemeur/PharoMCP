Class {
	#name : 'MCPRequestProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'processor'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'helpers' }
MCPRequestProcessorTest >> initializeResultWithVersion: aStringOrNil [

	| params response |
	params := Dictionary new.
	aStringOrNil ifNotNil: [ :version | params at: 'protocolVersion' put: version ].
	response := processor processRawRequest: (self request: 'initialize' id: 1 params: params).
	^ (self parse: response) at: 'result'
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> initializeWithVersion: aStringOrNil [

	^ (self initializeResultWithVersion: aStringOrNil) at: 'protocolVersion'
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> parse: jsonString [
	^ NeoJSONReader fromString: jsonString
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> request: method id: id params: params [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'method' put: method;
		at: 'params' put: params;
		yourself)
]

{ #category : 'running' }
MCPRequestProcessorTest >> setUp [
	super setUp.
	processor := MCPRequestProcessor new.
	processor registerTool: (MCPTool
		name: 'echo'
		description: 'Returns the input text unchanged'
		schema: Dictionary new
		handler: [ :args | args at: 'text' ifAbsent: [ '' ] ]).
	processor registerTool: (MCPTool
		name: 'add'
		description: 'Adds two integers'
		schema: Dictionary new
		handler: [ :args | ((args at: 'a') + (args at: 'b')) printString ])
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeAnswersLatestForUnknownVersion [

	self
		assert: (self initializeWithVersion: '1999-01-01')
		equals: MCPRequestProcessor latestProtocolVersion
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeAnswersLatestWhenClientSendsNoVersion [

	self
		assert: (self initializeWithVersion: nil)
		equals: MCPRequestProcessor latestProtocolVersion
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeCapabilitiesIncludeTools [
	| response result |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: Dictionary new).
	result := (self parse: response) at: 'result'.
	self assert: ((result at: 'capabilities') includesKey: 'tools')
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeCarriesInstructions [

	| instructions |
	instructions := (self initializeResultWithVersion: '2025-11-25') at: 'instructions'.
	self assert: instructions isString.
	self deny: instructions isEmpty
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeEchoesSupportedVersionRequestedByClient [

	self assert: (self initializeWithVersion: '2025-06-18') equals: '2025-06-18'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeResponseHasCorrectId [
	| response dict |
	response := processor processRawRequest:
		(self request: 'initialize' id: 42 params: Dictionary new).
	dict := self parse: response.
	self assert: (dict at: 'id') equals: 42.
	self assert: (dict at: 'jsonrpc') equals: '2.0'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeReturnsProtocolVersion [
	| response result |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: (Dictionary new
			at: 'protocolVersion' put: '2024-11-05';
			at: 'capabilities' put: Dictionary new;
			at: 'clientInfo' put: (Dictionary new at: 'name' put: 'test'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	self assert: (result at: 'protocolVersion') equals: '2024-11-05'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeReturnsServerInfo [
	| response result serverInfo |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: Dictionary new).
	result := (self parse: response) at: 'result'.
	serverInfo := result at: 'serverInfo'.
	self assert: (serverInfo at: 'name') equals: 'PharoMCP'.
	self assert: (serverInfo includesKey: 'version')
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testLongResultIsTruncatedWithItsSizeStated [

	| size response text |
	size := MCPRequestProcessor maximumResultSize + 500.
	processor registerTool: (MCPTool
		name: 'long'
		description: 'Answers a long string'
		schema: Dictionary new
		handler: [ :args | String new: size withAll: $x ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'long';
		at: 'arguments' put: Dictionary new;
		yourself)).
	text := (((self parse: response) at: 'result') at: 'content') first at: 'text'.
	self assert: (text beginsWith: (String new: MCPRequestProcessor maximumResultSize withAll: $x)).
	self assert: (text endsWith: '(truncated, ' , size printString , ' characters)')
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testMissingRequiredArgumentIsToolError [

	| response result called |
	called := false.
	processor registerTool: (MCPTool
		name: 'needs_text'
		description: 'Needs a text argument'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'text' put: (Dictionary new at: 'type' put: 'string'; yourself);
				yourself);
			at: 'required' put: #( 'text' );
			yourself)
		handler: [ :args | called := true. args at: 'text' ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'needs_text';
		at: 'arguments' put: Dictionary new;
		yourself)).
	result := (self parse: response) at: 'result'.
	self deny: called.
	self assert: (result at: 'isError').
	self
		assert: ((result at: 'content') first at: 'text')
		equals: 'Missing required argument: text'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testNotificationReturnsNil [
	| response |
	response := processor processRawRequest:
		(NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'method' put: 'notifications/initialized';
			at: 'params' put: Dictionary new;
			yourself)).
	self assert: response isNil
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testParseErrorReturns32700 [
	| response error |
	response := processor processRawRequest: 'this is not json at all'.
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32700
]

{ #category : 'tests - ping' }
MCPRequestProcessorTest >> testPingAnswersEmptyResult [

	| response result |
	response := processor processRawRequest: (self request: 'ping' id: 7 params: Dictionary new).
	result := self parse: response.
	self assert: (result at: 'id') equals: 7.
	self deny: (result includesKey: 'error').
	self assert: (result at: 'result') isEmpty
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testResponseIsValidJson [

	| response |
	response := processor processRawRequest:
		            (self request: 'tools/list' id: 1 params: Dictionary new).
	self assert: response isString.
	NeoJSONReader fromString: response
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testServerInfoCarriesNameAndVersion [

	| serverInfo |
	serverInfo := (self initializeResultWithVersion: '2025-11-25') at: 'serverInfo'.
	self assert: (serverInfo at: 'name') equals: MCPRequestProcessor serverName.
	self assert: (serverInfo at: 'version') equals: MCPRequestProcessor serverVersion
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testShortResultIsNotTruncated [

	| response text |
	processor registerTool: (MCPTool
		name: 'short'
		description: 'Answers a short string'
		schema: Dictionary new
		handler: [ :args | 'brief' ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'short';
		at: 'arguments' put: Dictionary new;
		yourself)).
	text := (((self parse: response) at: 'result') at: 'content') first at: 'text'.
	self assert: text equals: 'brief'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolCanBeRegisteredAfterInit [
	| newTool response tools toolNames |
	newTool := MCPTool
		name: 'late_tool'
		description: 'Added after init'
		schema: Dictionary new
		handler: [ :args | 'ok' ].
	processor registerTool: newTool.
	response := processor processRawRequest:
		(self request: 'tools/list' id: 1 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	toolNames := tools collect: [ :t | t at: 'name' ].
	self assert: (toolNames includes: 'late_tool')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolErrorSetsIsError [
	| errorTool response result |
	errorTool := MCPTool
		name: 'exploder'
		description: 'Always fails'
		schema: Dictionary new
		handler: [ :args | Error signal: 'boom' ].
	processor registerTool: errorTool.
	response := processor processRawRequest:
		(self request: 'tools/call' id: 7 params: (Dictionary new
			at: 'name' put: 'exploder';
			at: 'arguments' put: Dictionary new;
			yourself)).
	result := (self parse: response) at: 'result'.
	self assert: (result at: 'isError').
	self assert: (((result at: 'content') first at: 'text') includesSubstring: 'boom')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallIsErrorFalseOnSuccess [
	| response result |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 3 params: (Dictionary new
			at: 'name' put: 'echo';
			at: 'arguments' put: (Dictionary new at: 'text' put: 'hi'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	self deny: (result at: 'isError')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallReturnsTextContent [
	| response result content |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 3 params: (Dictionary new
			at: 'name' put: 'echo';
			at: 'arguments' put: (Dictionary new at: 'text' put: 'hello world'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	content := result at: 'content'.
	self assert: content isArray.
	self assert: content size equals: 1.
	self assert: ((content first) at: 'type') equals: 'text'.
	self assert: ((content first) at: 'text') equals: 'hello world'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallWithArithmeticTool [
	| response result content |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 4 params: (Dictionary new
			at: 'name' put: 'add';
			at: 'arguments' put: (Dictionary new
				at: 'a' put: 10;
				at: 'b' put: 32;
				yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	content := (result at: 'content') first.
	self assert: (content at: 'text') equals: '42'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsListReturnsAllRegisteredTools [
	| response tools |
	response := processor processRawRequest:
		(self request: 'tools/list' id: 2 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	self assert: tools size equals: 2
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsListToolHasRequiredFields [
	| response tools firstTool |
	response := processor processRawRequest:
		(self request: 'tools/list' id: 2 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	firstTool := tools detect: [ :t | (t at: 'name') = 'echo' ].
	self assert: (firstTool includesKey: 'name').
	self assert: (firstTool includesKey: 'description').
	self assert: (firstTool includesKey: 'inputSchema')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testUnknownMethodReturnsError32601 [
	| response error |
	response := processor processRawRequest:
		(self request: 'nonexistent/method' id: 5 params: Dictionary new).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32601
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testUnknownToolIsProtocolError [

	| response error |
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'no_such_tool';
		at: 'arguments' put: Dictionary new;
		yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32602
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testUnknownToolReturnsError32602 [
	| response error |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 6 params: (Dictionary new
			at: 'name' put: 'no_such_tool';
			at: 'arguments' put: Dictionary new;
			yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32602
]
