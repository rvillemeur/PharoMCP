"
The find_senders tool: answers one line per method that sends a selector, as ClassName >> #selector. The answer is capped, because a selector like printString has thousands of senders and a client reading them all learns nothing more than the first hundred say.
"
Class {
	#name : 'MCPFindSendersTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPFindSendersTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPFindSendersTool >> description [

	^ 'Find all methods that send a given message selector. Returns ClassName >> #selector per sender, capped at 100.'
]

{ #category : 'calling' }
MCPFindSendersTool >> execute: arguments [

	^ MCPPharoTools findSendersOf: (arguments at: 'selector')
]

{ #category : 'accessing' }
MCPFindSendersTool >> inputSchema [

	^ self
		schemaWithProperties: { 'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Message selector to search for (e.g. printString)') }
		required: #('selector')
]

{ #category : 'accessing' }
MCPFindSendersTool >> name [

	^ 'find_senders'
]

{ #category : 'accessing' }
MCPFindSendersTool >> title [

	^ 'Find the senders of a selector'
]
