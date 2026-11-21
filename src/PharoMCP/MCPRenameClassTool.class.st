"
The class_rename tool: renames one class through Pharo's own rename change. References inside method source are left alone, so the answer tells the caller to run search_source for the old name next.
"
Class {
	#name : 'MCPRenameClassTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRenameClassTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPRenameClassTool >> description [

	^ 'Rename a class in the image. Does not auto-update references in method source — use search_source after renaming to find callers that need updating.'
]

{ #category : 'calling' }
MCPRenameClassTool >> execute: arguments [

	^ MCPPharoTools
		renameClass: (arguments at: 'old_name')
		to: (arguments at: 'new_name')
]

{ #category : 'accessing' }
MCPRenameClassTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'old_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Current class name').
			'new_name' -> (self schemaPropertyOfType: 'string' describedAs: 'New class name. Must not already exist.') }
		required: #('old_name' 'new_name')
]

{ #category : 'accessing' }
MCPRenameClassTool >> name [

	^ 'class_rename'
]

{ #category : 'accessing' }
MCPRenameClassTool >> title [

	^ 'Rename a class'
]
