"
The package_create tool: installs one package in the image. It refuses a name already taken, so a client that means to add a package never silently reuses the one that is there.
"
Class {
	#name : 'MCPCreatePackageTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPCreatePackageTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPCreatePackageTool >> description [

	^ 'Create a new package in the image. Fails if a package with that name already exists.'
]

{ #category : 'calling' }
MCPCreatePackageTool >> execute: arguments [

	^ MCPPharoTools createPackage: (arguments at: 'package')
]

{ #category : 'accessing' }
MCPCreatePackageTool >> inputSchema [

	^ self
		schemaWithProperties: { 'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name, e.g. MyApp or MyApp-Core') }
		required: #('package')
]

{ #category : 'accessing' }
MCPCreatePackageTool >> name [

	^ 'package_create'
]

{ #category : 'accessing' }
MCPCreatePackageTool >> title [

	^ 'Create a package'
]
