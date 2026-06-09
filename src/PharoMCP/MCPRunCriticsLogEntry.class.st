"
Log entry for run_critics tool calls. requestArgument shows the class or package name being critiqued.
"
Class {
	#name : 'MCPRunCriticsLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPRunCriticsLogEntry class >> toolName [
	^ 'run_critics'
]

{ #category : 'accessing' }
MCPRunCriticsLogEntry >> requestArgument [
	| args |
	args := self parsedArguments.
	(args includesKey: 'package') ifTrue: [ ^ args at: 'package' ].
	^ args at: 'class_name' ifAbsent: [ '' ]
]
