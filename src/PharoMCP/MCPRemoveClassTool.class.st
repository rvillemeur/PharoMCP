"
The class_remove tool: removes one class from the image. It refuses a class that still has subclasses, naming them, because removing it would leave them with no superclass; nothing undoes the removal.
"
Class {
	#name : 'MCPRemoveClassTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRemoveClassTool >> annotations [

	^ self destructiveHints
]

{ #category : 'accessing' }
MCPRemoveClassTool >> description [

	^ 'Remove a class from the image. Fails if the class has subclasses. Cannot be undone — verify the class name before calling.'
]

{ #category : 'calling' }
MCPRemoveClassTool >> execute: arguments [

	^ MCPPharoTools removeClass: (arguments at: 'class_name')
]

{ #category : 'accessing' }
MCPRemoveClassTool >> inputSchema [

	^ self
		schemaWithProperties: { 'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class to remove') }
		required: #('class_name')
]

{ #category : 'accessing' }
MCPRemoveClassTool >> name [

	^ 'class_remove'
]

{ #category : 'accessing' }
MCPRemoveClassTool >> title [

	^ 'Remove a class'
]
