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

{ #category : 'private' }
MCPLogger >> entryClassForRequest: reqJson [
	| parsed method toolName |
	[ parsed := NeoJSONReader fromString: reqJson ]
		on: Error do: [ :e | ^ MCPLogEntry ].
	method := parsed at: 'method' ifAbsent: [ ^ MCPLogEntry ].
	(method beginsWith: 'notifications/') ifTrue: [ ^ MCPNotificationLogEntry ].
	method = 'tools/call' ifTrue: [
		toolName := ((parsed at: 'params' ifAbsent: [ Dictionary new ]) at: 'name' ifAbsent: [ '' ]).
		^ MCPLogEntry allSubclasses
			detect: [ :c | (c class includesSelector: #toolName) and: [ c toolName = toolName ] ]
			ifNone: [ MCPLogEntry ] ].
	^ MCPLogEntry allSubclasses
		detect: [ :c | (c class includesSelector: #toolName) and: [ c toolName = method ] ]
		ifNone: [ MCPLogEntry ]
]

{ #category : 'accessing' }
MCPLogger >> exportAsJson [
	^ NeoJSONWriter toStringPretty: (entries collect: [ :e | e asDictionary ]) asArray
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
	| entryClass entry |
	entryClass := self entryClassForRequest: requestJson.
	entry := entryClass request: requestJson response: responseJson.
	entries add: entry.
	^ entry
]
