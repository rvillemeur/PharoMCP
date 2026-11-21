"
The search_source tool: finds text in method source, over one package or over one class with both its sides. A package argument wins over a class name, and a call that names neither is refused — searching every method of the image would answer slowly and say too much.
"
Class {
	#name : 'MCPSearchSourceTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPSearchSourceTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPSearchSourceTool >> description [

	^ 'Search method source code for a text pattern across a class or package. Returns matching method names with the first matching line. Use for finding string literals, comments, or any text that find_implementors/find_senders cannot locate.'
]

{ #category : 'calling' }
MCPSearchSourceTool >> execute: arguments [

	| pattern caseSensitive |
	pattern := arguments at: 'pattern'.
	caseSensitive := arguments at: 'case_sensitive' ifAbsent: [ false ].
	^ (arguments at: 'package' ifAbsent: [ nil ])
		ifNotNil: [ :package |
			MCPPharoTools searchSourceFor: pattern inPackage: package caseSensitive: caseSensitive ]
		ifNil: [
			(arguments at: 'class_name' ifAbsent: [ nil ])
				ifNotNil: [ :className |
					MCPPharoTools searchSourceFor: pattern inClass: className caseSensitive: caseSensitive ]
				ifNil: [ MCPToolError signal: 'provide class_name or package' ] ]
]

{ #category : 'accessing' }
MCPSearchSourceTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Text to search for in method source code').
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Search methods of this class (instance + class side). Required unless package given.').
			'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Search all methods in this package. Overrides class_name.').
			'case_sensitive' -> (self schemaPropertyOfType: 'boolean' describedAs: 'Case-sensitive match. Defaults to false.') }
		required: #('pattern')
]

{ #category : 'accessing' }
MCPSearchSourceTool >> name [

	^ 'search_source'
]

{ #category : 'accessing' }
MCPSearchSourceTool >> title [

	^ 'Search method source'
]
