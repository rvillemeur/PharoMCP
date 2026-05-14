Class {
	#name : 'MCPServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP',
	#tag : 'Tests'
}

{ #category : 'running' }
MCPServerTest >> setUp [
	server := MCPServer onPort: 17777
]

{ #category : 'running' }
MCPServerTest >> tearDown [
	server isRunning ifTrue: [ server stop ]
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

{ #category : 'tests' }
MCPServerTest >> testStartAndStop [
	server start.
	self assert: server isRunning.
	server stop.
	self deny: server isRunning
]
