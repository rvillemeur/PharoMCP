"
The find_implementors tool: answers one line per class that implements a selector. It is the companion of find_senders — one says who calls a message, this one says who answers it.
"
Class {
	#name : 'MCPFindImplementorsTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPFindImplementorsTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPFindImplementorsTool >> description [

	^ 'Find all classes that implement a given method selector.'
]

{ #category : 'calling' }
MCPFindImplementorsTool >> execute: arguments [

	^ MCPPharoTools findImplementorsOf: (arguments at: 'selector')
]

{ #category : 'accessing' }
MCPFindImplementorsTool >> inputSchema [

	^ self
		schemaWithProperties: { 'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Method selector to search for (e.g. printOn:)') }
		required: #('selector')
]

{ #category : 'accessing' }
MCPFindImplementorsTool >> name [

	^ 'find_implementors'
]

{ #category : 'accessing' }
MCPFindImplementorsTool >> title [

	^ 'Find the implementors of a selector'
]
