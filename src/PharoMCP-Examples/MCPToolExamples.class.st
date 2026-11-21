"
Examples of MCPTool: a tool built the plain way, and one carrying a title, annotations and an output schema.
"
Class {
	#name : 'MCPToolExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPToolExamples class >> annotatedTool [

	<sampleInstance>
	^ MCPPharoTools listClassesTool
]

{ #category : 'examples' }
MCPToolExamples class >> tool [

	<sampleInstance>
	^ MCPTool
		name: 'greet'
		description: 'Answers a greeting'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'name' put: (Dictionary new at: 'type' put: 'string'; yourself);
				yourself);
			at: 'required' put: #( 'name' );
			yourself)
		handler: [ :args | 'Hello, ' , (args at: 'name') ]
]

{ #category : 'examples' }
MCPToolExamples class >> toolAnsweringStructuredContent [

	<sampleInstance>
	^ MCPPharoTools runTestsTool
]
