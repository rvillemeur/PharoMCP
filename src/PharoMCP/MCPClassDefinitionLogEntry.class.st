"
Log entry for class_definition tool calls. requestArgument shows the class name.
"
Class {
	#name : 'MCPClassDefinitionLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPClassDefinitionLogEntry class >> toolName [
	^ 'class_definition'
]

{ #category : 'accessing' }
MCPClassDefinitionLogEntry >> requestArgument [
	^ self parsedArguments at: 'className' ifAbsent: [ '' ]
]
