Class {
	#name : 'MCPFindSendersLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPFindSendersLogEntry class >> toolName [
	^ 'find_senders'
]

{ #category : 'accessing' }
MCPFindSendersLogEntry >> requestArgument [
	^ self parsedArguments at: 'selector' ifAbsent: [ '' ]
]
