"
The list_methods tool: answers one line per method of a class, protocol first, sorted by protocol and then by selector, so a reader sees the class grouped the way the browser groups it. The side argument picks the instance side or the class side.
"
Class {
	#name : 'MCPListMethodsTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPListMethodsTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPListMethodsTool >> description [

	^ 'List all methods defined on a class with their protocol. Use side "class" for class-side methods.'
]

{ #category : 'calling' }
MCPListMethodsTool >> execute: arguments [

	^ MCPPharoTools
		listMethodsOn: (arguments at: 'className')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
]

{ #category : 'accessing' }
MCPListMethodsTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
			'side' -> self schemaSideProperty }
		required: #('className')
]

{ #category : 'accessing' }
MCPListMethodsTool >> name [

	^ 'list_methods'
]

{ #category : 'accessing' }
MCPListMethodsTool >> title [

	^ 'List the methods of a class'
]
