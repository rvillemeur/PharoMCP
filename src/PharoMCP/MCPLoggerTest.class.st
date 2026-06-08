Class {
	#name : 'MCPLoggerTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP',
	#package : 'PharoMCP'
}

{ #category : 'tests' }
MCPLoggerTest >> testClearEmptiesEntries [
	| logger req |
	logger := MCPLogger new.
	req := self toolCallRequest: 'evaluate_pharo' args: Dictionary new.
	logger log: req response: '{}'.
	logger clear.
	self assert: logger entries isEmpty
]

{ #category : 'tests' }
MCPLoggerTest >> testExportAsJsonAsDictionaryKeys [
	| logger req entry |
	logger := MCPLogger new.
	req := self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself).
	logger log: req response: '{}'.
	entry := (NeoJSONReader fromString: logger exportAsJson) first.
	self assert: (entry includesKey: 'timestamp').
	self assert: (entry includesKey: 'method').
	self assert: (entry includesKey: 'toolName').
	self assert: (entry includesKey: 'request')
]

{ #category : 'tests' }
MCPLoggerTest >> testExportAsJsonContainsToolName [
	| logger req json |
	logger := MCPLogger new.
	req := self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself).
	logger log: req response: '{}'.
	json := logger exportAsJson.
	self assert: (json includesSubstring: 'evaluate_pharo')
]

{ #category : 'tests' }
MCPLoggerTest >> testExportAsJsonIsValidJson [
	| logger req parsed |
	logger := MCPLogger new.
	req := self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself).
	logger log: req response: '{}'.
	parsed := NeoJSONReader fromString: logger exportAsJson.
	self assert: parsed isArray
]

{ #category : 'tests' }
MCPLoggerTest >> testExportAsJsonWhenEmpty [
	| parsed |
	parsed := NeoJSONReader fromString: MCPLogger new exportAsJson.
	self assert: parsed isArray.
	self assert: parsed isEmpty
]

{ #category : 'tests' }
MCPLoggerTest >> testInitiallyEmpty [
	self assert: MCPLogger new entries isEmpty
]

{ #category : 'tests' }
MCPLoggerTest >> testIsActiveReturnsTrue [
	self assert: MCPLogger new isActive
]

{ #category : 'tests' }
MCPLoggerTest >> testLogAddsEntry [
	| logger req |
	logger := MCPLogger new.
	req := self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself).
	logger log: req response: '{}'.
	self assert: logger entries size equals: 1
]

{ #category : 'helpers' }
MCPLoggerTest >> toolCallRequest: toolName args: argDict [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'method' put: 'tools/call';
		at: 'params' put: (Dictionary new
			at: 'name' put: toolName;
			at: 'arguments' put: argDict;
			yourself);
		yourself)
]
