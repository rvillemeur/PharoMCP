"
The class_comment tool: reads a class comment when the call carries no comment argument, and writes it when it does. One tool does both because a client that can read a comment is the one that rewrites it, and the argument it sends says which it meant.
"
Class {
	#name : 'MCPClassCommentTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPClassCommentTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPClassCommentTool >> description [

	^ 'Get or set the comment (documentation) on a class. Omit the comment parameter to read; supply it to write.'
]

{ #category : 'calling' }
MCPClassCommentTool >> execute: arguments [

	^ (arguments at: 'comment' ifAbsent: [ nil ])
		ifNil: [ MCPPharoTools getClassComment: (arguments at: 'class_name') ]
		ifNotNil: [ :comment |
			MCPPharoTools setClassComment: comment onClass: (arguments at: 'class_name') ]
]

{ #category : 'accessing' }
MCPClassCommentTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
			'comment' -> (self schemaPropertyOfType: 'string' describedAs: 'New comment text. Omit to read the current comment.') }
		required: #('class_name')
]

{ #category : 'accessing' }
MCPClassCommentTool >> name [

	^ 'class_comment'
]

{ #category : 'accessing' }
MCPClassCommentTool >> title [

	^ 'Read or write a class comment'
]
