Class {
	#name : 'MCPLogEntryTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP',
	#tag : 'Tests'
}

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
MCPLogEntryTest >> testRequestArgumentForClassDefinition [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'class_definition' args: (Dictionary new at: 'className' put: 'OrderedCollection'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'OrderedCollection'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForEvalTool [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'evaluate_pharo' args: (Dictionary new at: 'code' put: '42 factorial'; yourself))
		response: ''.
	self assert: entry requestArgument equals: '42 factorial'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForListClasses [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'list_classes' args: (Dictionary new at: 'pattern' put: 'MCP'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'MCP'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForListMethods [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'list_methods' args: (Dictionary new at: 'className' put: 'String'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'String'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForMethodSource [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'method_source' args: (Dictionary new at: 'className' put: 'String'; at: 'methodName' put: 'size'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'String >> #size'
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
MCPLogEntryTest >> testRequestArgumentForRunTestsClass [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'run_tests' args: (Dictionary new at: 'class_name' put: 'MCPToolTest'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'MCPToolTest'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForRunTestsPackage [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'run_tests' args: (Dictionary new at: 'package' put: 'PharoMCP'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'PharoMCP'
]

{ #category : 'tests - requestArgument' }
MCPLogEntryTest >> testRequestArgumentForRunTestsWithSelector [
	| entry |
	entry := MCPLogEntry
		request: (self toolCallRequest: 'run_tests' args: (Dictionary new at: 'class_name' put: 'MCPToolTest'; at: 'selector' put: 'testToolCreation'; yourself))
		response: ''.
	self assert: entry requestArgument equals: 'MCPToolTest >> #testToolCreation'
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
