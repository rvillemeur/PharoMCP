"
Null object logger. Used when logging is disabled — all operations are no-ops.
"
Class {
	#name : 'MCPNullLogger',
	#superclass : 'Object',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPNullLogger >> clear [
	"no-op"
]

{ #category : 'accessing' }
MCPNullLogger >> entries [
	^ #()
]

{ #category : 'accessing' }
MCPNullLogger >> exportAsJson [
	^ '[]'
]

{ #category : 'testing' }
MCPNullLogger >> isActive [
	^ false
]

{ #category : 'logging' }
MCPNullLogger >> log: requestJson response: responseJson [
	^ nil
]
