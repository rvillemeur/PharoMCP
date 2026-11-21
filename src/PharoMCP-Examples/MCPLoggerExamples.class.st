"
Examples of MCPLogger: a logger holding one entry of each kind the server records.
"
Class {
	#name : 'MCPLoggerExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPLoggerExamples class >> logger [

	<sampleInstance>
	| logger |
	logger := MCPLogger new.
	logger
		log: (MCPLogEntryExamples requestNamed: 'initialize' params: Dictionary new)
		response: MCPRequestProcessorExamples initializeResponse.
	logger
		log: (MCPLogEntryExamples requestNamed: 'tools/list' params: Dictionary new)
		response: MCPRequestProcessorExamples toolsListResponse.
	logger
		log: (MCPLogEntryExamples requestNamed: 'tools/call' params: (Dictionary new
			at: 'name' put: 'run_tests';
			at: 'arguments' put: (Dictionary new at: 'class_name' put: 'MCPToolTest'; yourself);
			yourself))
		response: '{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{}"}]}}'.
	^ logger
]
