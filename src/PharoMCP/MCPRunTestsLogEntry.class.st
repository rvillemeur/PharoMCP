Class {
	#name : 'MCPRunTestsLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPRunTestsLogEntry class >> toolName [
	^ 'run_tests'
]

{ #category : 'accessing' }
MCPRunTestsLogEntry >> requestArgument [
	| args cls sel |
	args := self parsedArguments.
	(args includesKey: 'package') ifTrue: [ ^ args at: 'package' ].
	cls := args at: 'class_name' ifAbsent: [ '' ].
	sel := args at: 'selector' ifAbsent: [ nil ].
	^ sel ifNil: [ cls ] ifNotNil: [ cls , ' >> #' , sel ]
]
