"
The compile_method tool: compiles one method on a class, instance side or class side, and answers the selector it installed. The source may arrive with LF line endings, which MCPPharoTools normalises to CR before compiling, because Pharo source is CR-only and a client cannot be relied on to send it that way.
"
Class {
	#name : 'MCPCompileMethodTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPCompileMethodTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPCompileMethodTool >> description [

	^ 'Compile a method on a class. Returns the selector on success. Use side "class" for class-side methods. LF line endings are normalised automatically.'
]

{ #category : 'calling' }
MCPCompileMethodTool >> execute: arguments [

	^ MCPPharoTools
		compileMethod: (arguments at: 'source')
		onClass: (arguments at: 'class_name')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
		classified: (arguments at: 'protocol' ifAbsent: [ 'as yet unclassified' ])
]

{ #category : 'accessing' }
MCPCompileMethodTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
			'source' -> (self schemaPropertyOfType: 'string' describedAs: 'Full method source including selector').
			'side' -> self schemaSideProperty.
			'protocol' -> (self schemaPropertyOfType: 'string' describedAs: 'Protocol name. Defaults to ''as yet unclassified''.') }
		required: #('class_name' 'source')
]

{ #category : 'accessing' }
MCPCompileMethodTool >> name [

	^ 'compile_method'
]

{ #category : 'accessing' }
MCPCompileMethodTool >> title [

	^ 'Compile a method'
]
