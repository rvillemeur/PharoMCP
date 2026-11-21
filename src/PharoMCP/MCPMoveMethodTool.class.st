"
The method_move tool: compiles one method on the target class with its protocol kept, then removes it from the source class. It refuses a target that already implements the selector, so the move never overwrites a method the caller did not name.
"
Class {
	#name : 'MCPMoveMethodTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPMoveMethodTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPMoveMethodTool >> description [

	^ 'Move a method from one class to another, preserving source and protocol. Fails if the target class already defines the selector.'
]

{ #category : 'calling' }
MCPMoveMethodTool >> execute: arguments [

	^ MCPPharoTools
		moveMethod: (arguments at: 'selector')
		fromClass: (arguments at: 'class_name')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
		toClass: (arguments at: 'target_class')
]

{ #category : 'accessing' }
MCPMoveMethodTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Source class name').
			'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Selector to move').
			'target_class' -> (self schemaPropertyOfType: 'string' describedAs: 'Destination class name').
			'side' -> self schemaSideProperty }
		required: #('class_name' 'selector' 'target_class')
]

{ #category : 'accessing' }
MCPMoveMethodTool >> name [

	^ 'method_move'
]

{ #category : 'accessing' }
MCPMoveMethodTool >> title [

	^ 'Move a method to another class'
]
