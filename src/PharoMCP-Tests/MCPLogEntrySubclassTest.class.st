Class {
	#name : 'MCPLogEntrySubclassTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'helpers' }
MCPLogEntrySubclassTest >> entryOfClass: aClass forTool: toolName args: argDict [
	^ aClass new
		initializeFromRequest: (self toolCallRequest: toolName args: argDict)
		response: '' 
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testClassDefinitionLogEntryRequestArgument [
	| entry |
	entry := self entryOfClass: MCPClassDefinitionLogEntry forTool: 'class_definition' args:
		(Dictionary new at: 'className' put: 'OrderedCollection'; yourself).
	self assert: entry requestArgument equals: 'OrderedCollection'
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testClassDefinitionLogEntryToolName [
	self assert: MCPClassDefinitionLogEntry toolName equals: 'class_definition'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testEvalLogEntryRequestArgument [
	| entry |
	entry := self entryOfClass: MCPEvalLogEntry forTool: 'evaluate_pharo' args:
		(Dictionary new at: 'code' put: '42 factorial'; yourself).
	self assert: entry requestArgument equals: '42 factorial'
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testEvalLogEntryToolName [
	self assert: MCPEvalLogEntry toolName equals: 'evaluate_pharo'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testInitializeLogEntryRequestArgument [
	| entry |
	entry := MCPInitializeLogEntry new
		initializeFromRequest: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
		response: ''.
	self assert: entry requestArgument equals: '' 
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testInitializeLogEntryToolName [
	self assert: MCPInitializeLogEntry toolName equals: 'initialize'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testListClassesLogEntryRequestArgument [
	| entry |
	entry := self entryOfClass: MCPListClassesLogEntry forTool: 'list_classes' args:
		(Dictionary new at: 'pattern' put: 'MCP'; yourself).
	self assert: entry requestArgument equals: 'MCP'
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testListClassesLogEntryToolName [
	self assert: MCPListClassesLogEntry toolName equals: 'list_classes'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testListMethodsLogEntryRequestArgument [
	| entry |
	entry := self entryOfClass: MCPListMethodsLogEntry forTool: 'list_methods' args:
		(Dictionary new at: 'className' put: 'String'; yourself).
	self assert: entry requestArgument equals: 'String'
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testListMethodsLogEntryToolName [
	self assert: MCPListMethodsLogEntry toolName equals: 'list_methods'
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerCreatesEvalEntryForEvalTool [
	| entry |
	entry := MCPLogger new log: (self toolCallRequest: 'evaluate_pharo' args: Dictionary new) response: ''.
	self assert: entry class equals: MCPEvalLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerCreatesInitializeEntry [
	| entry |
	entry := MCPLogger new log: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' response: ''.
	self assert: entry class equals: MCPInitializeLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerCreatesNotificationEntry [
	| entry |
	entry := MCPLogger new log: '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' response: ''.
	self assert: entry class equals: MCPNotificationLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerCreatesRunTestsEntry [
	| entry |
	entry := MCPLogger new log: (self toolCallRequest: 'run_tests' args: Dictionary new) response: ''.
	self assert: entry class equals: MCPRunTestsLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerCreatesToolsListEntry [
	| entry |
	entry := MCPLogger new log: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' response: ''.
	self assert: entry class equals: MCPToolsListLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerFallsBackToBaseForUnknownTool [
	| entry |
	entry := MCPLogger new log: (self toolCallRequest: 'no_such_tool' args: Dictionary new) response: ''.
	self assert: entry class equals: MCPLogEntry
]

{ #category : 'tests - typed logger' }
MCPLogEntrySubclassTest >> testLoggerFallsBackToBaseOnParseError [
	| entry |
	entry := MCPLogger new log: 'not json' response: ''.
	self assert: entry class equals: MCPLogEntry
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testMethodSourceLogEntryRequestArgument [
	| entry |
	entry := self entryOfClass: MCPMethodSourceLogEntry forTool: 'method_source' args:
		(Dictionary new at: 'className' put: 'String'; at: 'methodName' put: 'size'; yourself).
	self assert: entry requestArgument equals: 'String >> #size'
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testMethodSourceLogEntryToolName [
	self assert: MCPMethodSourceLogEntry toolName equals: 'method_source'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testNotificationLogEntryRequestArgument [
	| entry |
	entry := MCPNotificationLogEntry new
		initializeFromRequest: '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}'
		response: ''.
	self assert: entry requestArgument equals: '' 
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testRunTestsLogEntryToolName [
	self assert: MCPRunTestsLogEntry toolName equals: 'run_tests'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testRunTestsLogEntryWithClass [
	| entry |
	entry := self entryOfClass: MCPRunTestsLogEntry forTool: 'run_tests' args:
		(Dictionary new at: 'class_name' put: 'MCPToolTest'; yourself).
	self assert: entry requestArgument equals: 'MCPToolTest'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testRunTestsLogEntryWithPackage [
	| entry |
	entry := self entryOfClass: MCPRunTestsLogEntry forTool: 'run_tests' args:
		(Dictionary new at: 'package' put: 'PharoMCP'; yourself).
	self assert: entry requestArgument equals: 'PharoMCP'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testRunTestsLogEntryWithSelector [
	| entry |
	entry := self entryOfClass: MCPRunTestsLogEntry forTool: 'run_tests' args:
		(Dictionary new at: 'class_name' put: 'MCPToolTest'; at: 'selector' put: 'testToolCreation'; yourself).
	self assert: entry requestArgument equals: 'MCPToolTest >> #testToolCreation'
]

{ #category : 'tests - requestArgument' }
MCPLogEntrySubclassTest >> testToolsListLogEntryRequestArgument [
	| entry |
	entry := MCPToolsListLogEntry new
		initializeFromRequest: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
		response: ''.
	self assert: entry requestArgument equals: '' 
]

{ #category : 'tests - toolNames' }
MCPLogEntrySubclassTest >> testToolsListLogEntryToolName [
	self assert: MCPToolsListLogEntry toolName equals: 'tools/list'
]

{ #category : 'helpers' }
MCPLogEntrySubclassTest >> toolCallRequest: toolName args: argDict [
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
