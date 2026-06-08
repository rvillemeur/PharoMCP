Class {
	#name : 'MCPFindImplementorsLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPFindImplementorsLogEntry class >> toolName [
	^ 'find_implementors'
]

{ #category : 'accessing' }
MCPFindImplementorsLogEntry >> requestArgument [
	^ self parsedArguments at: 'selector' ifAbsent: [ '' ]
]
