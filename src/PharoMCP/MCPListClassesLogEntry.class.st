"
Log entry for list_classes tool calls. requestArgument shows the search pattern.
"
Class {
	#name : 'MCPListClassesLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPListClassesLogEntry class >> toolName [
	^ 'list_classes'
]

{ #category : 'accessing' }
MCPListClassesLogEntry >> requestArgument [
	^ self parsedArguments at: 'pattern' ifAbsent: [ '' ]
]
