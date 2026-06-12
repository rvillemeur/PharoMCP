Class {
	#name : 'MCPLoggerTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
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

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForMethodNonToolCall [
	| logger parsed cls |
	logger := MCPLogger new.
	parsed := Dictionary new.
	cls := logger entryClassForMethod: 'tools/list' in: parsed.
	self assert: (cls inheritsFrom: MCPLogEntry)
]

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForMethodToolCall [
	| logger parsed cls |
	logger := MCPLogger new.
	parsed := Dictionary new
		at: 'params' put: (Dictionary new at: 'name' put: 'evaluate_pharo'; yourself);
		yourself.
	cls := logger entryClassForMethod: 'tools/call' in: parsed.
	self deny: cls isNil
]

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForMethodUnknownFallsBack [
	| logger cls |
	logger := MCPLogger new.
	cls := logger entryClassForMethod: 'unknown/method' in: Dictionary new.
	self assert: cls equals: MCPLogEntry
]

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForRequestInvalidJson [
	| logger cls |
	logger := MCPLogger new.
	cls := logger entryClassForRequest: 'not json'.
	self assert: cls equals: MCPLogEntry
]

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForRequestMissingMethod [
	| logger cls |
	logger := MCPLogger new.
	cls := logger entryClassForRequest: '{"jsonrpc":"2.0"}'.
	self assert: cls equals: MCPLogEntry
]

{ #category : 'tests - private' }
MCPLoggerTest >> testEntryClassForRequestNotification [
	| logger cls |
	logger := MCPLogger new.
	cls := logger entryClassForRequest: '{"method":"notifications/initialized"}'.
	self assert: cls equals: MCPNotificationLogEntry
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

{ #category : 'tests - private' }
MCPLoggerTest >> testParseJsonInvalidStringCallsBlock [
	| logger called |
	logger := MCPLogger new.
	called := false.
	logger parseJson: 'not json' ifInvalid: [called := true. 'fallback'].
	self assert: called
]

{ #category : 'tests - private' }
MCPLoggerTest >> testParseJsonValidString [
	| logger result |
	logger := MCPLogger new.
	result := logger parseJson: '{"a":1}' ifInvalid: [self fail: 'should not call block'].
	self assert: (result at: 'a') equals: 1
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
