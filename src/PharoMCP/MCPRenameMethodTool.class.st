"
The method_rename tool: rewrites one method under a new selector and removes the old one. It does not touch the senders, because Pharo's rename transformation hangs on an RBNamespace this server has already changed; the answer tells the caller to run find_senders next.
"
Class {
	#name : 'MCPRenameMethodTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRenameMethodTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPRenameMethodTool >> description [

	^ 'Rename a method selector on a class. Rewrites the method source and removes the old selector. Does NOT auto-update senders — use find_senders after renaming to locate callers that need updating.'
]

{ #category : 'calling' }
MCPRenameMethodTool >> execute: arguments [

	^ MCPPharoTools
		renameMethod: (arguments at: 'old_selector')
		onClass: (arguments at: 'class_name')
		side: (arguments at: 'side' ifAbsent: [ 'instance' ])
		to: (arguments at: 'new_selector')
]

{ #category : 'accessing' }
MCPRenameMethodTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class that defines the method').
			'old_selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Current selector to rename').
			'new_selector' -> (self schemaPropertyOfType: 'string' describedAs: 'New selector. Must have the same number of arguments.').
			'side' -> self schemaSideProperty }
		required: #('class_name' 'old_selector' 'new_selector')
]

{ #category : 'accessing' }
MCPRenameMethodTool >> name [

	^ 'method_rename'
]

{ #category : 'accessing' }
MCPRenameMethodTool >> title [

	^ 'Rename a method'
]
