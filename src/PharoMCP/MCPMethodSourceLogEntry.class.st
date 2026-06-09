"
Log entry for method_source tool calls. requestArgument shows className>>methodName.
"
Class {
	#name : 'MCPMethodSourceLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPMethodSourceLogEntry class >> toolName [
	^ 'method_source'
]

{ #category : 'accessing' }
MCPMethodSourceLogEntry >> requestArgument [
	| args |
	args := self parsedArguments.
	^ (args at: 'className' ifAbsent: [ '' ]) , ' >> #' , (args at: 'methodName' ifAbsent: [ '' ])
]
