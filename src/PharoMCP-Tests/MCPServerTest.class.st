Class {
	#name : 'MCPServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'running' }
MCPServerTest >> setUp [
	super setUp.
	server := MCPServer onPort: 17777
]

{ #category : 'running' }
MCPServerTest >> tearDown [
	server isRunning ifTrue: [ server stop ].
	super tearDown
]

{ #category : 'tests - private' }
MCPServerTest >> testBuildResponseForNilReturns200NoBody [
	| response |
	response := server buildResponseFor: nil.
	self assert: response statusLine code equals: 200.
	self assert: response entity isNil
]

{ #category : 'tests - private' }
MCPServerTest >> testBuildResponseForStringReturnsJsonResponse [
	| response |
	response := server buildResponseFor: '{"result":42}'.
	self assert: response statusLine code equals: 200.
	self assert: response entity contentType equals: ZnMimeType applicationJson
]

{ #category : 'tests' }
MCPServerTest >> testCustomPort [
	self assert: server port equals: 17777
]

{ #category : 'tests' }
MCPServerTest >> testDefaultPort [
	| defaultServer |
	defaultServer := MCPServer default.
	self assert: defaultServer port equals: 7777
]

{ #category : 'tests - private' }
MCPServerTest >> testExtractBodyFromRequestWithEntity [
	| request |
	request := ZnRequest post: 'http://localhost/'.
	request entity: (ZnEntity with: '{"test":1}' type: ZnMimeType applicationJson).
	self assert: (server extractBodyFrom: request) equals: '{"test":1}'
]

{ #category : 'tests - private' }
MCPServerTest >> testExtractBodyFromRequestWithoutEntity [
	| request |
	request := ZnRequest post: 'http://localhost/'.
	self assert: (server extractBodyFrom: request) equals: '{}'
]

{ #category : 'tests - private' }
MCPServerTest >> testHandleNonPostRequest [
	| response |
	response := server handleNonPostRequest.
	self assert: response statusLine code equals: 405.
	self assert: response entity string equals: 'Method Not Allowed'
]

{ #category : 'tests - private' }
MCPServerTest >> testHandleOptionsRequest [
	| response |
	response := server handleOptionsRequest.
	self assert: response statusLine code equals: 200.
	self assert: (response headers at: 'Access-Control-Allow-Origin') equals: '*'
]

{ #category : 'tests' }
MCPServerTest >> testHttpInitialize [
	| client response body result |
	server start.
	client := ZnClient new.
	client url: 'http://localhost:17777/'.
	client entity: (ZnEntity
		with: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
		type: ZnMimeType applicationJson).
	response := client post.
	body := NeoJSONReader fromString: response.
	result := body at: 'result'.
	self assert: (result at: 'protocolVersion') equals: '2024-11-05'
]

{ #category : 'tests' }
MCPServerTest >> testHttpPostReturnsJson [
	| client response body |
	server start.
	client := ZnClient new.
	client url: 'http://localhost:17777/'.
	client entity: (ZnEntity
		with: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
		type: ZnMimeType applicationJson).
	response := client post.
	body := NeoJSONReader fromString: response.
	self assert: (body includesKey: 'result').
	self assert: ((body at: 'result') includesKey: 'tools')
]

{ #category : 'tests' }
MCPServerTest >> testHttpToolCall [
	| client response body result content |
	server start.
	client := ZnClient new.
	client url: 'http://localhost:17777/'.
	client entity: (ZnEntity
		with: '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate_pharo","arguments":{"code":"3 + 4"}}}'
		type: ZnMimeType applicationJson).
	response := client post.
	body := NeoJSONReader fromString: response.
	result := body at: 'result'.
	content := (result at: 'content') first.
	self assert: (content at: 'text') equals: '7'
]

{ #category : 'tests' }
MCPServerTest >> testInitializesWithPharoTools [
	| tools |
	tools := server processor tools.
	self assert: (tools includesKey: 'evaluate_pharo').
	self assert: (tools includesKey: 'list_classes').
	self assert: (tools includesKey: 'class_definition').
	self assert: (tools includesKey: 'method_source').
	self assert: (tools includesKey: 'list_methods')
]

{ #category : 'tests - private' }
MCPServerTest >> testLogRequestResponseAbsorbsErrors [
	"logRequest:response: must never propagate — server absorbs logging errors"
	| logger |
	logger := MCPNullLogger new.
	server instVarAt: (MCPServer instVarIndexFor: #logger ifAbsent: [1]) put: logger.
	self shouldnt: [ server logRequest: '{}' response: nil ] raise: Error
]

{ #category : 'tests' }
MCPServerTest >> testNotRunningBeforeStart [
	self deny: server isRunning
]

{ #category : 'tests' }
MCPServerTest >> testRegisterCustomTool [
	| customTool |
	customTool := MCPTool
		name: 'custom'
		description: 'Custom tool'
		schema: Dictionary new
		handler: [ :args | 'custom result' ].
	server registerTool: customTool.
	self assert: (server processor tools includesKey: 'custom')
]

{ #category : 'tests - private' }
MCPServerTest >> testSafeProcessReturnsErrorJsonOnBadInput [
	| result parsed |
	result := server safeProcess: 'not json at all'.
	parsed := NeoJSONReader fromString: result.
	self assert: (parsed includesKey: 'error').
	self assert: ((parsed at: 'error') includesKey: 'code')
]

{ #category : 'tests - private' }
MCPServerTest >> testSafeProcessValidRequest [
	| body result |
	body := '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'.
	result := server safeProcess: body.
	self assert: (result includesSubstring: 'tools')
]

{ #category : 'tests' }
MCPServerTest >> testStartAndStop [
	server start.
	self assert: server isRunning.
	server stop.
	self deny: server isRunning
]
