"
The class_hierarchy tool: answers the superclass chain of a class from Object down, then its direct subclasses. It reads the live hierarchy rather than a stored list, so a class created a moment ago is already in it.
"
Class {
	#name : 'MCPClassHierarchyTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPClassHierarchyTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPClassHierarchyTool >> description [

	^ 'Show superclass chain and direct subclasses of a class.'
]

{ #category : 'calling' }
MCPClassHierarchyTool >> execute: arguments [

	^ MCPPharoTools classHierarchyOf: (arguments at: 'class_name')
]

{ #category : 'accessing' }
MCPClassHierarchyTool >> inputSchema [

	^ self
		schemaWithProperties: { 'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class') }
		required: #('class_name')
]

{ #category : 'accessing' }
MCPClassHierarchyTool >> name [

	^ 'class_hierarchy'
]

{ #category : 'accessing' }
MCPClassHierarchyTool >> title [

	^ 'Show a class hierarchy'
]
