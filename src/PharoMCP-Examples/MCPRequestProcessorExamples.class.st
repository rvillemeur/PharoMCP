"
Examples of MCPRequestProcessor: a processor holding the twenty-two tools of this image, and the answers it gives to initialize and to tools/list.
"
Class {
	#name : 'MCPRequestProcessorExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPRequestProcessorExamples class >> initializeResponse [

	<sampleInstance>
	^ self processor processRawRequest: (NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'method' put: 'initialize';
		at: 'params' put: (Dictionary new at: 'protocolVersion' put: MCPRequestProcessor latestProtocolVersion; yourself);
		yourself))
]

{ #category : 'examples' }
MCPRequestProcessorExamples class >> processor [

	<sampleInstance>
	| processor |
	processor := MCPRequestProcessor new.
	MCPPharoTools allTools do: [ :each | processor registerTool: each ].
	^ processor
]

{ #category : 'examples' }
MCPRequestProcessorExamples class >> toolsListResponse [

	<sampleInstance>
	^ self processor processRawRequest: (NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 2;
		at: 'method' put: 'tools/list';
		at: 'params' put: Dictionary new;
		yourself))
]
