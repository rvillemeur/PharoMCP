"
Examples of what the tool factories answer: the whole tool table, the result of running one test class, and the report dictionary a client receives for it.
"
Class {
	#name : 'MCPPharoToolsExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPPharoToolsExamples class >> testReport [

	<sampleInstance>
	^ MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil
]

{ #category : 'examples' }
MCPPharoToolsExamples class >> testResult [

	<sampleInstance>
	| result |
	result := MCPTestResult new.
	MCPToolTest suite run: result.
	^ result
]

{ #category : 'examples' }
MCPPharoToolsExamples class >> tools [

	<sampleInstance>
	^ MCPPharoTools allTools
]
