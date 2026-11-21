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

{ #category : 'accessing' }
MCPLogEntry class >> entryClasses [

	"Written out rather than read off the hierarchy, so each subclass is referenced from
	 code and a reader grepping for its name finds the one place that chooses it."

	^ { MCPClassDefinitionLogEntry. MCPClassHierarchyLogEntry. MCPEvalLogEntry.
		MCPFindImplementorsLogEntry. MCPFindSendersLogEntry. MCPInitializeLogEntry.
		MCPListClassesLogEntry. MCPListMethodsLogEntry. MCPListPackagesLogEntry.
		MCPMethodSourceLogEntry. MCPNotificationLogEntry. MCPRunCriticsLogEntry.
		MCPRunTestsLogEntry. MCPToolsListLogEntry }
]

{ #category : 'inspector' }
MCPLogEntry class >> inspectorRequestMapping: aBuilder [

	<inspectorPresentationOrder: 1 title: 'Request mapping'>

	"Each row asks MCPLogger the real question rather than restating the table, so a
	 subclass whose toolName stops matching shows up here as a row answering MCPLogEntry."

	| logger rows |
	logger := MCPLogger new.
	rows := self entryClasses asSortedCollection: [ :a :b | a name < b name ].
	rows := rows asOrderedCollection collect: [ :each |
		| method chosen |
		method := (each class includesSelector: #toolName)
			ifTrue: [ each toolName ]
			ifFalse: [ 'notifications/initialized' ].
		chosen := logger entryClassForRequest: (self requestJsonForMethod: method).
		each -> chosen ].
	^ aBuilder newTable
		items: rows asArray;
		addColumn: (SpStringTableColumn title: 'Entry class' evaluated: [ :each | each key name ]);
		addColumn: (SpStringTableColumn title: 'Request' evaluated: [ :each |
			(each key class includesSelector: #toolName)
				ifTrue: [ each key toolName ]
				ifFalse: [ 'notifications/*' ] ]);
		addColumn: (SpStringTableColumn title: 'Logger picks' evaluated: [ :each | each value name ]);
		yourself
]

{ #category : 'inspector' }
MCPLogEntry class >> inspectorRequestMappingContext: aContext [

	"The mapping is a rule the whole hierarchy keeps, so only the root shows it."

	aContext active: self superclass = Object
]

{ #category : 'instance creation' }
MCPLogEntry class >> request: reqJson response: respJson [
	^ self new
		initializeFromRequest: reqJson response: respJson;
		yourself
]

{ #category : 'inspector' }
MCPLogEntry class >> requestJsonForMethod: aString [

	"A tool name reaches the logger inside a tools/call request; a bare method name is the
	 method itself."

	(aString includes: $/) ifTrue: [
		^ '{"jsonrpc":"2.0","id":1,"method":"' , aString , '"}' ].
	^ '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"' , aString , '"}}'
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

	toolArgs ifNil: [ ^ '' ].
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
	parsed := [ NeoJSONReader fromString: responseJson ]
		on: Error do: [ :e | ^ nil ].
	result := parsed at: 'result' ifAbsent: [ ^ nil ].
	result isDictionary ifFalse: [ ^ nil ].
	content := result at: 'content' ifAbsent: [ ^ nil ].
	content isArray ifFalse: [ ^ nil ].
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

{ #category : 'inspector' }
MCPLogEntry >> inspectionDetails: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Details'>
	^ (StSimpleInspectorBuilder on: aBuilder)
		key: 'Tool' value: (toolName ifNil: [ '—' ]);
		key: 'Method' value: (method ifNil: [ '—' ]);
		key: 'Timestamp' value: timestamp printString;
		key: 'Args' value: (toolArgs ifNil: [ '—' ] ifNotNil: [ :a | NeoJSONWriter toString: a ]);
		table
]

{ #category : 'accessing' }
MCPLogEntry >> method [
	^ method
]

{ #category : 'private' }
MCPLogEntry >> parseRequest: reqJson [
	| parsed params |
	parsed := [ NeoJSONReader fromString: reqJson ]
		on: Error
		do: [ :e | method := '(parse error)'. ^ self ].
	method := parsed at: 'method' ifAbsent: [ '?' ].
	params := parsed at: 'params' ifAbsent: [ Dictionary new ].
	method = 'tools/call' ifFalse: [ ^ self ].
	self parseToolCallParams: params
]

{ #category : 'private' }
MCPLogEntry >> parseToolCallParams: params [
	| args argStr |
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
	parsed := [ NeoJSONReader fromString: requestJson ]
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
