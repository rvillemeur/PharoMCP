"
The evaluate_pharo tool: compiles and runs the code a client sends and answers the result's printString. It is the one destructive tool whose effect the server cannot describe, since the code decides what it does. No error handling here: the request processor catches what the compiler or the code signals and marks the tool result as a failure, which a handler answering a string could not do.
"
Class {
	#name : 'MCPEvaluateTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPEvaluateTool >> annotations [

	^ self destructiveHints
]

{ #category : 'accessing' }
MCPEvaluateTool >> description [

	^ 'Evaluate Pharo Smalltalk code and return the result as a string. Supports any valid Pharo expression or sequence of statements.'
]

{ #category : 'calling' }
MCPEvaluateTool >> execute: arguments [

	^ (OpalCompiler new evaluate: (arguments at: 'code')) printString
]

{ #category : 'accessing' }
MCPEvaluateTool >> inputSchema [

	^ self
		schemaWithProperties: { 'code' -> (self schemaPropertyOfType: 'string' describedAs: 'Pharo Smalltalk code to evaluate') }
		required: #('code')
]

{ #category : 'accessing' }
MCPEvaluateTool >> name [

	^ 'evaluate_pharo'
]

{ #category : 'accessing' }
MCPEvaluateTool >> title [

	^ 'Evaluate Pharo code'
]
