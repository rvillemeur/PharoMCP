Class {
	#name : 'MCPToolTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'tests' }
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

{ #category : 'tests' }
MCPToolTest >> testAsDictionaryCarriesTitleAndAnnotations [

	| tool dictionary |
	tool := MCPTool
		name: 'browse'
		description: 'Reads the image without changing it'
		schema: Dictionary new
		handler: [ :args | 'ok' ].
	tool
		title: 'Browse the image';
		readOnly;
		outputSchema: (Dictionary new at: 'type' put: 'object'; yourself).
	dictionary := tool asDictionary.
	self assert: (dictionary at: 'title') equals: 'Browse the image'.
	self assert: ((dictionary at: 'annotations') at: 'readOnlyHint').
	self deny: ((dictionary at: 'annotations') at: 'destructiveHint').
	self deny: ((dictionary at: 'annotations') at: 'openWorldHint').
	self assert: ((dictionary at: 'outputSchema') at: 'type') equals: 'object'
]

{ #category : 'tests' }
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

{ #category : 'tests' }
MCPToolTest >> testAsDictionaryOmitsAbsentOptionalFields [

	| tool |
	tool := MCPTool
		name: 'plain'
		description: 'A tool built the way every existing tool is built'
		schema: Dictionary new
		handler: [ :args | 'ok' ].
	self assert: tool asDictionary keys asSortedCollection asArray equals: #( 'description' 'inputSchema' 'name' )
]

{ #category : 'tests - validation' }
MCPToolTest >> testMissingRequiredArgumentsNamesWhatIsAbsent [

	| tool |
	tool := MCPTool
		name: 'needs_two'
		description: 'Needs two arguments'
		schema: (Dictionary new
			at: 'required' put: #( 'first' 'second' );
			yourself)
		handler: [ :args | '' ].
	self
		assert: (tool missingRequiredArgumentsIn: (Dictionary new at: 'first' put: 1; yourself))
		equals: #( 'second' ) asOrderedCollection.
	self assert: (tool missingRequiredArgumentsIn: (Dictionary new
		at: 'first' put: 1;
		at: 'second' put: 2;
		yourself)) isEmpty
]

{ #category : 'tests' }
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

{ #category : 'tests' }
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

{ #category : 'tests' }
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

{ #category : 'tests - validation' }
MCPToolTest >> testToolWithoutRequiredListMissesNothing [

	| tool |
	tool := MCPTool
		name: 'needs_nothing'
		description: 'Needs no argument'
		schema: Dictionary new
		handler: [ :args | '' ].
	self assert: (tool missingRequiredArgumentsIn: Dictionary new) isEmpty
]
