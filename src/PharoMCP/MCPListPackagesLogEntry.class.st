"
Log entry for list_packages tool calls. requestArgument shows the optional filter pattern.
"
Class {
	#name : 'MCPListPackagesLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPListPackagesLogEntry class >> toolName [
	^ 'list_packages'
]

{ #category : 'accessing' }
MCPListPackagesLogEntry >> requestArgument [
	^ self parsedArguments at: 'pattern' ifAbsent: [ '' ]
]
