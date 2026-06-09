"
Log entry for evaluate_pharo tool calls. requestArgument shows the code snippet.
"
Class {
	#name : 'MCPEvalLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPEvalLogEntry class >> toolName [
	^ 'evaluate_pharo'
]

{ #category : 'accessing' }
MCPEvalLogEntry >> requestArgument [
	^ self parsedArguments at: 'code' ifAbsent: [ '' ]
]
