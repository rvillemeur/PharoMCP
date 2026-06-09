"
Log entry for find_implementors tool calls. requestArgument shows the selector being searched.
"
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
