"
The list_classes tool: answers the classes whose name holds a substring, capped at fifty. The pattern is required and must not be empty, because the image holds some fifteen thousand classes and a client asking for all of them learns nothing from the answer.
"
Class {
	#name : 'MCPListClassesTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPListClassesTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPListClassesTool >> description [

	^ 'Search for classes in the Pharo image by name pattern. Returns up to 50 matching class names.'
]

{ #category : 'calling' }
MCPListClassesTool >> execute: arguments [

	| pattern |
	pattern := arguments at: 'pattern' ifAbsent: [ '' ].
	^ pattern isEmpty
		ifTrue: [ 'Provide a non-empty pattern. The image contains thousands of classes.' ]
		ifFalse: [ MCPPharoTools listClassesMatching: pattern ]
]

{ #category : 'accessing' }
MCPListClassesTool >> inputSchema [

	^ self
		schemaWithProperties: { 'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Substring to search for in class names (case-insensitive). Required — the image has thousands of classes.') }
		required: #('pattern')
]

{ #category : 'accessing' }
MCPListClassesTool >> name [

	^ 'list_classes'
]

{ #category : 'accessing' }
MCPListClassesTool >> title [

	^ 'List classes'
]
