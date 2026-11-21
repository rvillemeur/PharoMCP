"
Examples of MCPLogEntry and its subclasses: one entry per request shape the logger recognises.
"
Class {
	#name : 'MCPLogEntryExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPLogEntryExamples class >> initializeEntry [

	<sampleInstance>
	^ MCPLogger new
		log: (self requestNamed: 'initialize' params: Dictionary new)
		response: MCPRequestProcessorExamples initializeResponse
]

{ #category : 'examples' }
MCPLogEntryExamples class >> notificationEntry [

	<sampleInstance>
	^ MCPLogger new
		log: (NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'method' put: 'notifications/initialized';
			yourself))
		response: nil
]

{ #category : 'examples' }
MCPLogEntryExamples class >> requestNamed: aMethodName params: aDictionary [

	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'method' put: aMethodName;
		at: 'params' put: aDictionary;
		yourself)
]

{ #category : 'examples' }
MCPLogEntryExamples class >> toolCallEntry [

	<sampleInstance>
	^ MCPLogger new
		log: (self requestNamed: 'tools/call' params: (Dictionary new
			at: 'name' put: 'list_classes';
			at: 'arguments' put: (Dictionary new at: 'pattern' put: 'MCP'; yourself);
			yourself))
		response: '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"MCPServer"}]}}'
]
