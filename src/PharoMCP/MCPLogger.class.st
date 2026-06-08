"
Active MCP interaction logger. Stores MCPLogEntry instances in an OrderedCollection
and returns each new entry to the caller for announcement.
"
Class {
	#name : 'MCPLogger',
	#superclass : 'Object',
	#instVars : [
		'entries'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPLogger >> clear [
	entries := OrderedCollection new
]

{ #category : 'accessing' }
MCPLogger >> entries [
	^ entries
]

{ #category : 'initialization' }
MCPLogger >> initialize [
	entries := OrderedCollection new
]

{ #category : 'testing' }
MCPLogger >> isActive [
	^ true
]

{ #category : 'logging' }
MCPLogger >> log: requestJson response: responseJson [
	| entry |
	entry := MCPLogEntry request: requestJson response: responseJson.
	entries add: entry.
	^ entry
]
