Class {
	#name : 'MCPLogEntryTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP',
	#tag : 'Tests'
}

{ #category : 'tests' }
MCPLogEntryTest >> testAsDictionaryHasRequiredKeys [
	| entry dict |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself))
		response: (self toolCallResponse: '42').
	dict := entry asDictionary.
	#('timestamp' 'method' 'toolName' 'requestArgument' 'request' 'response') do: [ :k |
		self assert: (dict includesKey: k) ]
]

{ #category : 'tests' }
MCPLogEntryTest >> testAsDictionaryRequestIsParsed [
	| entry dict |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42'; yourself))
		response: (self toolCallResponse: '42').
	dict := entry asDictionary.
	self assert: (dict at: 'request') isDictionary
]

{ #category : 'tests' }
MCPLogEntryTest >> testDisplayArgsLongStringTruncated [
	| entry longCode |
	longCode := String new: 100 withAll: $x.
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: longCode; yourself))
		response: '{}'.
	self assert: entry displayArgs size <= 83.
	self assert: (entry displayArgs endsWith: '...')
]

{ #category : 'tests' }
MCPLogEntryTest >> testDisplayArgsShortString [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42 factorial'; yourself))
		response: '{}'.
	self assert: (entry displayArgs includesSubstring: '42 factorial')
]

{ #category : 'tests' }
MCPLogEntryTest >> testDisplayMethodFallsBackToMethod [
	| entry req |
	req := NeoJSONWriter toString: (Dictionary new at: 'jsonrpc' put: '2.0'; at: 'method' put: 'initialize'; yourself).
	entry := MCPLogEntry request: req response: '{}'.
	self assert: entry displayMethod equals: 'initialize'
]

{ #category : 'tests' }
MCPLogEntryTest >> testDisplayMethodForToolCall [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: Dictionary new)
		response: '{}'.
	self assert: entry displayMethod equals: 'tools/call: evaluate_pharo'
]

{ #category : 'tests - extractedResponseText' }
MCPLogEntryTest >> testExtractedResponseTextFromEmptyResponse [
	| entry |
	entry := MCPLogEntry request: '{"method":"tools/list"}' response: ''.
	self assert: entry extractedResponseText isNil
]

{ #category : 'tests - extractedResponseText' }
MCPLogEntryTest >> testExtractedResponseTextFromInitializeResponse [
	| entry |
	entry := MCPLogEntry
		request: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"'
		response: '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05"}}'.
	self assert: entry extractedResponseText isNil
]

{ #category : 'tests - extractedResponseText' }
MCPLogEntryTest >> testExtractedResponseTextFromMalformedResponse [
	| entry |
	entry := MCPLogEntry request: '{}' response: 'not json'.
	self assert: entry extractedResponseText isNil
]

{ #category : 'tests - extractedResponseText' }
MCPLogEntryTest >> testExtractedResponseTextFromMultiLineResponse [
	| entry text |
	text := 'line1' , String lf , 'line2'.
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: Dictionary new)
		response: (self toolCallResponse: text).
	self assert: entry extractedResponseText equals: text
]

{ #category : 'tests - extractedResponseText' }
MCPLogEntryTest >> testExtractedResponseTextFromToolCallResponse [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '3+4'; yourself))
		response: (self toolCallResponse: '7').
	self assert: entry extractedResponseText equals: '7'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForNonToolCall [
	| entry |
	entry := MCPLogEntry
		request: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
		response: ''.
	self assert: entry requestArgument equals: '' 
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForToolsList [
	| entry |
	entry := MCPLogEntry
		request: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
		response: ''.
	self assert: entry requestArgument equals: '' 
]

{ #category : 'helpers' }
MCPLogEntryTest >> toolCallRequest: toolName args: argDict [
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

{ #category : 'helpers' }
MCPLogEntryTest >> toolCallResponse: text [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'result' put: (Dictionary new
			at: 'content' put: (Array with: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: text;
				yourself));
			at: 'isError' put: false;
			yourself);
		yourself)
]
