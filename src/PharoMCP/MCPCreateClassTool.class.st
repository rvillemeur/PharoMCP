"
The class_create tool: installs one class with its slots in a package, defaulting the superclass to Object and the slots to none. It refuses a name the image already holds, so it never silently redefines a class the caller did not mean to touch; compile_method adds the methods afterwards.
"
Class {
	#name : 'MCPCreateClassTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPCreateClassTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPCreateClassTool >> description [

	^ 'Create a new Pharo class. Fails if the class already exists. Use compile_method to add methods after creation.'
]

{ #category : 'calling' }
MCPCreateClassTool >> execute: arguments [

	^ MCPPharoTools
		createClass: (arguments at: 'class_name')
		superclass: (arguments at: 'superclass_name' ifAbsent: [ 'Object' ])
		instanceVariables: (arguments at: 'instance_variables' ifAbsent: [ #() ])
		package: (arguments at: 'package')
]

{ #category : 'accessing' }
MCPCreateClassTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the new class').
			'superclass_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Superclass name. Defaults to Object.').
			'instance_variables' -> (Dictionary new
				at: 'type' put: 'array';
				at: 'items' put: (Dictionary new at: 'type' put: 'string'; yourself);
				at: 'description' put: 'Instance variable names. Defaults to none.';
				yourself).
			'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name, e.g. MyApp or MyApp-Core.') }
		required: #('class_name' 'package')
]

{ #category : 'accessing' }
MCPCreateClassTool >> name [

	^ 'class_create'
]

{ #category : 'accessing' }
MCPCreateClassTool >> title [

	^ 'Create a class'
]
