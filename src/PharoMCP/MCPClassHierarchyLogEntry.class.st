Class {
	#name : 'MCPClassHierarchyLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPClassHierarchyLogEntry class >> toolName [
	^ 'class_hierarchy'
]

{ #category : 'accessing' }
MCPClassHierarchyLogEntry >> requestArgument [
	^ self parsedArguments at: 'class_name' ifAbsent: [ '' ]
]
