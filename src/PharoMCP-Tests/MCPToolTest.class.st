Class {
	#name : #MCPToolTest,
	#superclass : #TestCase,
	#category : #'PharoMCP-Tests'
}

{ #category : #tests }
MCPToolTest >> testToolCreation [
	| tool |
	tool := MCPTool
		name: 'my_tool'
		description: 'A test tool'
		schema: (Dictionary new at: 'type' put: 'object'; yourself)
		handler: [ :args | 'done' ].
	self assert: tool name equals: 'my_tool'.
	self assert: tool description equals: 'A test tool'.
	self assert: (tool inputSchema at: 'type') equals: 'object'
]

{ #category : #tests }
MCPToolTest >> testToolCallWithBlock [
	| tool result |
	tool := MCPTool
		name: 'adder'
		description: 'Adds two numbers'
		schema: Dictionary new
		handler: [ :args | (args at: 'a') + (args at: 'b') ].
	result := tool call: (Dictionary new
		at: 'a' put: 3;
		at: 'b' put: 4;
		yourself).
	self assert: result equals: 7
]

{ #category : #tests }
MCPToolTest >> testToolCallWithStringResult [
	| tool result |
	tool := MCPTool
		name: 'greeter'
		description: 'Returns a greeting'
		schema: Dictionary new
		handler: [ :args | 'Hello, ' , (args at: 'name') ].
	result := tool call: (Dictionary new at: 'name' put: 'Pharo'; yourself).
	self assert: result equals: 'Hello, Pharo'
]

{ #category : #tests }
MCPToolTest >> testAsDictionary [
	| tool dict |
	tool := MCPTool
		name: 'the_tool'
		description: 'The description'
		schema: (Dictionary new at: 'type' put: 'object'; yourself)
		handler: [ :args | nil ].
	dict := tool asDictionary.
	self assert: (dict at: 'name') equals: 'the_tool'.
	self assert: (dict at: 'description') equals: 'The description'.
	self assert: (dict includesKey: 'inputSchema').
	self assert: ((dict at: 'inputSchema') at: 'type') equals: 'object'
]

{ #category : #tests }
MCPToolTest >> testAsDictionaryHasRequiredKeys [
	| tool dict |
	tool := MCPTool
		name: 'n'
		description: 'd'
		schema: Dictionary new
		handler: [ :args | nil ].
	dict := tool asDictionary.
	self assert: (dict includesKey: 'name').
	self assert: (dict includesKey: 'description').
	self assert: (dict includesKey: 'inputSchema')
]
