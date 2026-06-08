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

{ #category : 'private' }
MCPLogEntry >> formatArguments: args forTool: aToolName [
	aToolName = 'evaluate_pharo' ifTrue: [ ^ args at: 'code' ifAbsent: [ '' ] ].
	aToolName = 'list_classes' ifTrue: [ ^ args at: 'pattern' ifAbsent: [ '' ] ].
	aToolName = 'class_definition' ifTrue: [ ^ args at: 'className' ifAbsent: [ '' ] ].
	aToolName = 'list_methods' ifTrue: [ ^ args at: 'className' ifAbsent: [ '' ] ].
	aToolName = 'method_source' ifTrue: [
		^ (args at: 'className' ifAbsent: [ '' ]) , ' >> #' , (args at: 'methodName' ifAbsent: [ '' ]) ].
	aToolName = 'run_tests' ifTrue: [
		| cls sel |
		(args includesKey: 'package') ifTrue: [ ^ args at: 'package' ].
		cls := args at: 'class_name' ifAbsent: [ '' ].
		sel := args at: 'selector' ifAbsent: [ nil ].
		^ sel ifNil: [ cls ] ifNotNil: [ cls , ' >> #' , sel ] ].
	^ args isEmpty ifTrue: [ '' ] ifFalse: [ args values first printString ]
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

{ #category : 'accessing' }
MCPLogEntry >> requestArgument [
	| parsed params args |
	method = 'tools/call' ifFalse: [ ^ '' ].
	[ parsed := NeoJSONReader fromString: requestJson ]
		on: Error do: [ :e | ^ '' ].
	params := parsed at: 'params' ifAbsent: [ ^ '' ].
	args := params at: 'arguments' ifAbsent: [ ^ '' ].
	(args isKindOf: Dictionary) ifFalse: [ ^ '' ].
	^ self formatArguments: args forTool: toolName
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
