"
The delete_method tool: removes one method from a class, instance side or class side. It is destructive and nothing undoes it, so it refuses a selector the class does not implement rather than reporting success for a method that was never there.
"
Class {
	#name : 'MCPDeleteMethodTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPDeleteMethodTool >> annotations [

	^ self destructiveHints
]

{ #category : 'accessing' }
MCPDeleteMethodTool >> description [

	^ 'Remove a method from a class. Use side "class" for class-side methods. Cannot be undone — verify the selector before calling.'
]

{ #category : 'calling' }
MCPDeleteMethodTool >> execute: arguments [

	^ MCPPharoTools
		deleteMethod: (arguments at: 'selector')
		fromClass: (arguments at: 'class_name')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
]

{ #category : 'accessing' }
MCPDeleteMethodTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
			'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Method selector to remove (e.g. "printOn:" or "add:").').
			'side' -> self schemaSideProperty }
		required: #('class_name' 'selector')
]

{ #category : 'accessing' }
MCPDeleteMethodTool >> name [

	^ 'delete_method'
]

{ #category : 'accessing' }
MCPDeleteMethodTool >> title [

	^ 'Delete a method'
]
