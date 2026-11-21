"
The package_remove tool: removes one empty package. It refuses a package that still holds classes, naming their count, because removing it would take them with it; a client moves or removes them first.
"
Class {
	#name : 'MCPRemovePackageTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRemovePackageTool >> annotations [

	^ self destructiveHints
]

{ #category : 'accessing' }
MCPRemovePackageTool >> description [

	^ 'Remove an empty package from the image. Fails if the package still contains classes — remove or move them first.'
]

{ #category : 'calling' }
MCPRemovePackageTool >> execute: arguments [

	^ MCPPharoTools removePackage: (arguments at: 'package')
]

{ #category : 'accessing' }
MCPRemovePackageTool >> inputSchema [

	^ self
		schemaWithProperties: { 'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name to remove') }
		required: #('package')
]

{ #category : 'accessing' }
MCPRemovePackageTool >> name [

	^ 'package_remove'
]

{ #category : 'accessing' }
MCPRemovePackageTool >> title [

	^ 'Remove a package'
]
