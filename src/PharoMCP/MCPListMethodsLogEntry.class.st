"
Log entry for list_methods tool calls. requestArgument shows className and optional side.
"
Class {
	#name : 'MCPListMethodsLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPListMethodsLogEntry class >> toolName [
	^ 'list_methods'
]

{ #category : 'accessing' }
MCPListMethodsLogEntry >> requestArgument [
	^ self parsedArguments at: 'className' ifAbsent: [ '' ]
]
