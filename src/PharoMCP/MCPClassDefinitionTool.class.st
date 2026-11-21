"
The class_definition tool: answers the class definition Pharo itself prints, which names the superclass, the slots, the tag and the package. It reads the class through MCPPharoTools classNamed:, so a name the image does not hold comes back as a tool error naming it.
"
Class {
	#name : 'MCPClassDefinitionTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPClassDefinitionTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPClassDefinitionTool >> description [

	^ 'Get the definition of a Pharo class including its superclass, instance variables, and package.'
]

{ #category : 'calling' }
MCPClassDefinitionTool >> execute: arguments [

	^ (MCPPharoTools classNamed: (arguments at: 'className')) definitionString
]

{ #category : 'accessing' }
MCPClassDefinitionTool >> inputSchema [

	^ self
		schemaWithProperties: { 'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Exact name of the class') }
		required: #('className')
]

{ #category : 'accessing' }
MCPClassDefinitionTool >> name [

	^ 'class_definition'
]

{ #category : 'accessing' }
MCPClassDefinitionTool >> title [

	^ 'Show a class definition'
]
