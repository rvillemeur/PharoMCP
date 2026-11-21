"
The list_packages tool: answers one line per package with its class count and its test class count, filtered by a substring when the call carries one. The filter is optional because an image with thousands of packages is still worth listing whole when a client is looking for a name it half remembers.
"
Class {
	#name : 'MCPListPackagesTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPListPackagesTool >> annotations [

	^ self readOnlyHints
]

{ #category : 'accessing' }
MCPListPackagesTool >> description [

	^ 'List packages in the image with class and test class counts. Optionally filter by name pattern.'
]

{ #category : 'calling' }
MCPListPackagesTool >> execute: arguments [

	^ MCPPharoTools listPackagesMatching: (arguments at: 'pattern' ifAbsent: [ nil ])
]

{ #category : 'accessing' }
MCPListPackagesTool >> inputSchema [

	^ self
		schemaWithProperties: { 'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Optional substring to filter package names (case-insensitive)') }
		required: #()
]

{ #category : 'accessing' }
MCPListPackagesTool >> name [

	^ 'list_packages'
]

{ #category : 'accessing' }
MCPListPackagesTool >> title [

	^ 'List packages'
]
