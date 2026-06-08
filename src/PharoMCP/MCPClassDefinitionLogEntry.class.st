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
