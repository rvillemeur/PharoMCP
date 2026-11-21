"
The method_source tool: answers the source code of one method, on the instance side or the class side. A selector the class does not implement comes back as a tool error naming the selector and the class it was looked for in.
"
Class {
	#name : 'MCPMethodSourceTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPMethodSourceTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPMethodSourceTool >> description [

	^ 'Get the source code of a method. Use side "class" for class-side methods, "instance" for instance-side methods.'
]

{ #category : 'calling' }
MCPMethodSourceTool >> execute: arguments [

	^ MCPPharoTools
		methodSourceOf: (arguments at: 'methodName')
		onClass: (arguments at: 'className')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
]

{ #category : 'accessing' }
MCPMethodSourceTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
			'methodName' -> (self schemaPropertyOfType: 'string' describedAs: 'Selector of the method (e.g. "add:" or "printOn:")').
			'side' -> self schemaSideProperty }
		required: #( 'className' 'methodName' )
]

{ #category : 'accessing' }
MCPMethodSourceTool >> name [

	^ 'method_source'
]

{ #category : 'accessing' }
MCPMethodSourceTool >> title [

	^ 'Show method source'
]
