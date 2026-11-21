"
The run_critics tool: runs Renraku on one class or on every class of a package and answers one entry per critique with its rule, its title and the entity it is about. It declares an output schema and states the total next to the listed count, because a long report is cut and a client must see that it was.
"
Class {
	#name : 'MCPRunCriticsTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRunCriticsTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'private' }
MCPRunCriticsTool >> critiqueArraySchema [

	^ Dictionary new
		at: 'type' put: 'array';
		at: 'description' put: 'One entry per critique';
		at: 'items' put: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'rule' put: (self schemaPropertyOfType: 'string' describedAs: 'Name of the Renraku rule class');
				at: 'title' put: (self schemaPropertyOfType: 'string' describedAs: 'What the rule reports');
				at: 'entity' put: (self schemaPropertyOfType: 'string' describedAs: 'The class or method the critique is about');
				yourself);
			yourself);
		yourself
]

{ #category : 'accessing' }
MCPRunCriticsTool >> description [

	^ 'Run Renraku code critics on a class or all classes in a package. Returns rule violations with descriptions.'
]

{ #category : 'calling' }
MCPRunCriticsTool >> execute: arguments [

	^ (arguments at: 'package' ifAbsent: [ nil ])
		ifNotNil: [ :package | MCPPharoTools runCriticsOnPackage: package ]
		ifNil: [
			(arguments at: 'class_name' ifAbsent: [ nil ])
				ifNil: [ MCPToolError signal: 'provide class_name or package' ]
				ifNotNil: [ :className | MCPPharoTools runCriticsOnClass: className ] ]
]

{ #category : 'accessing' }
MCPRunCriticsTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Class to critique. Required unless package given.').
			'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name — critiques all classes. Overrides class_name.') }
		required: #()
]

{ #category : 'accessing' }
MCPRunCriticsTool >> name [

	^ 'run_critics'
]

{ #category : 'accessing' }
MCPRunCriticsTool >> outputSchema [

	^ Dictionary new
		at: 'type' put: 'object';
		at: 'properties' put: (Dictionary new
			at: 'target' put: (self schemaPropertyOfType: 'string' describedAs: 'Class or package the critics were run on');
			at: 'critiqueCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Critiques listed');
			at: 'totalCritiqueCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Critiques found, which is larger when the list was cut');
			at: 'critiques' put: self critiqueArraySchema;
			at: 'summary' put: (self schemaPropertyOfType: 'string' describedAs: 'The same report as human readable text');
			yourself);
		at: 'required' put: #( 'target' 'critiqueCount' 'totalCritiqueCount' 'critiques' 'summary' );
		yourself
]

{ #category : 'accessing' }
MCPRunCriticsTool >> title [

	^ 'Run the code critics'
]
