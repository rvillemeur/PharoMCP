"
Single logged MCP interaction: one request/response pair.

Parses the request JSON on creation to extract method, toolName, and a short
args preview for the log list. The raw JSON strings are kept for full display
in the detail panel.
"
Class {
	#name : 'MCPLogEntry',
	#superclass : 'Object',
	#instVars : [
		'timestamp',
		'requestJson',
		'responseJson',
		'method',
		'toolName',
		'toolArgs'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'instance creation' }
MCPLogEntry class >> request: reqJson response: respJson [
	^ self new
		initializeFromRequest: reqJson response: respJson;
		yourself
]

{ #category : 'accessing' }
MCPLogEntry >> asDictionary [
	| dict |
	dict := Dictionary new.
	dict at: 'timestamp' put: timestamp printString.
	dict at: 'method' put: (method ifNil: [ '?' ]).
	dict at: 'toolName' put: (toolName ifNil: [ '' ]).
	dict at: 'requestArgument' put: self requestArgument.
	dict at: 'request' put: ([ NeoJSONReader fromString: requestJson ]
		on: Error do: [ :e | requestJson ]).
	dict at: 'response' put: (responseJson isEmpty
		ifTrue: [ nil ]
		ifFalse: [ [ NeoJSONReader fromString: responseJson ]
			on: Error do: [ :e | responseJson ] ]).
	self extractedResponseText ifNotNil: [ :txt | dict at: 'result' put: txt ].
	^ dict
]

{ #category : 'accessing' }
MCPLogEntry >> displayArgs [
	toolArgs isNil ifTrue: [ ^ '' ].
	^ toolArgs size > 80
		ifTrue: [ (toolArgs copyFrom: 1 to: 80) , '...' ]
		ifFalse: [ toolArgs ]
]

{ #category : 'accessing' }
MCPLogEntry >> displayMethod [
	^ toolName
		ifNil: [ method ifNil: [ '?' ] ]
		ifNotNil: [ :n | method , ': ' , n ]
]

{ #category : 'accessing' }
MCPLogEntry >> extractedResponseText [
	| parsed result content |
	responseJson isEmpty ifTrue: [ ^ nil ].
	[ parsed := NeoJSONReader fromString: responseJson ]
		on: Error do: [ :e | ^ nil ].
	result := parsed at: 'result' ifAbsent: [ ^ nil ].
	(result isKindOf: Dictionary) ifFalse: [ ^ nil ].
	content := result at: 'content' ifAbsent: [ ^ nil ].
	(content isKindOf: Array) ifFalse: [ ^ nil ].
	content isEmpty ifTrue: [ ^ nil ].
	^ content first at: 'text' ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPLogEntry >> formattedRequestJson [
	^ [ NeoJSONWriter toStringPretty: (NeoJSONReader fromString: requestJson) ]
		on: Error
		do: [ :e | requestJson ]
]

{ #category : 'accessing' }
MCPLogEntry >> formattedResponseJson [
	responseJson isEmpty ifTrue: [ ^ '' ].
	^ [ NeoJSONWriter toStringPretty: (NeoJSONReader fromString: responseJson) ]
		on: Error
		do: [ :e | responseJson ]
]

{ #category : 'initialization' }
MCPLogEntry >> initializeFromRequest: reqJson response: respJson [
	timestamp := DateAndTime now.
	requestJson := reqJson.
	responseJson := respJson ifNil: [ '' ].
	self parseRequest: reqJson
]

{ #category : 'accessing' }
MCPLogEntry >> method [
	^ method
]

{ #category : 'private' }
MCPLogEntry >> parseRequest: reqJson [
	| parsed params args argStr |
	[ parsed := NeoJSONReader fromString: reqJson ]
		on: Error
		do: [ :e | method := '(parse error)'. ^ self ].
	method := parsed at: 'method' ifAbsent: [ '?' ].
	params := parsed at: 'params' ifAbsent: [ Dictionary new ].
	method = 'tools/call' ifFalse: [ ^ self ].
	toolName := params at: 'name' ifAbsent: [ '' ].
	args := params at: 'arguments' ifAbsent: [ Dictionary new ].
	argStr := args isEmpty
		ifTrue: [ '' ]
		ifFalse: [ args values first printString ].
	toolArgs := argStr size > 80
		ifTrue: [ (argStr copyFrom: 1 to: 80) , '...' ]
		ifFalse: [ argStr ]
]

{ #category : 'private' }
MCPLogEntry >> parsedArguments [
	"Returns arguments dict from a tools/call request, or empty dict on any error"
	| parsed params |
	method = 'tools/call' ifFalse: [ ^ Dictionary new ].
	[ parsed := NeoJSONReader fromString: requestJson ]
		on: Error do: [ :e | ^ Dictionary new ].
	params := parsed at: 'params' ifAbsent: [ ^ Dictionary new ].
	^ params at: 'arguments' ifAbsent: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPLogEntry >> requestArgument [
	| args |
	args := self parsedArguments.
	args isEmpty ifTrue: [ ^ '' ].
	^ args values first printString
]

{ #category : 'accessing' }
MCPLogEntry >> requestJson [
	^ requestJson
]

{ #category : 'accessing' }
MCPLogEntry >> responseJson [
	^ responseJson
]

{ #category : 'accessing' }
MCPLogEntry >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
MCPLogEntry >> toolName [
	^ toolName
]
