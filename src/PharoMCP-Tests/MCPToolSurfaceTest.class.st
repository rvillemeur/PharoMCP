"
I hold the published surface of every tool: its name, which arguments it takes, which of them are required, and the keys of the structured output the two reporting tools answer. The table in my class side is written out rather than read from the tools, because a difference between it and the image is a change every MCP client sees. I also hold the shape every tool class must have: an own execute:, a title, a description and the four annotation hints.
"
Class {
	#name : 'MCPToolSurfaceTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'surface' }
MCPToolSurfaceTest class >> expectedArrayItemKeys [
	"Tool name -> ( array key -> the keys of one entry of that array ). These are the rows a
	client reads out of the structured answer."

	^ Dictionary newFrom: {
		'run_tests' -> { 'failures' -> #('message' 'selector'). 'errors' -> #('message' 'selector') }.
		'run_critics' -> { 'critiques' -> #('entity' 'rule' 'title') } }
]

{ #category : 'surface' }
MCPToolSurfaceTest class >> expectedOutputSchemas [
	"Tool name -> the keys of the structured content it answers. Only the two reporting tools
	declare an output schema; every other tool answers text."

	^ Dictionary newFrom: {
		'run_tests' -> #('durationMilliseconds' 'erroredCount' 'errors' 'failedCount' 'failures' 'passedCount' 'runCount' 'selector' 'summary' 'target').
		'run_critics' -> #('critiqueCount' 'critiques' 'summary' 'target' 'totalCritiqueCount') }
]

{ #category : 'surface' }
MCPToolSurfaceTest class >> expectedSurface [
	"Tool name -> { required argument names. optional argument names }. Written out, not read
	from the tools: a difference between this table and the image is a change every MCP client
	sees. class_name and className are both here on purpose -- see CLAUDE.md."

	^ Dictionary newFrom: {
		'evaluate_pharo' -> #( #('code') #() ).
		'list_classes' -> #( #('pattern') #() ).
		'class_definition' -> #( #('className') #() ).
		'class_hierarchy' -> #( #('class_name') #() ).
		'class_comment' -> #( #('class_name') #('comment') ).
		'class_create' -> #( #('class_name' 'package') #('instance_variables' 'superclass_name') ).
		'class_remove' -> #( #('class_name') #() ).
		'class_rename' -> #( #('new_name' 'old_name') #() ).
		'list_methods' -> #( #('className') #('side') ).
		'method_source' -> #( #('className' 'methodName') #('side') ).
		'compile_method' -> #( #('class_name' 'source') #('protocol' 'side') ).
		'delete_method' -> #( #('class_name' 'selector') #('side') ).
		'method_rename' -> #( #('class_name' 'new_selector' 'old_selector') #('side') ).
		'method_move' -> #( #('class_name' 'selector' 'target_class') #('side') ).
		'find_senders' -> #( #('selector') #() ).
		'find_implementors' -> #( #('selector') #() ).
		'search_source' -> #( #('pattern') #('case_sensitive' 'class_name' 'package') ).
		'list_packages' -> #( #() #('pattern') ).
		'package_create' -> #( #('package') #() ).
		'package_remove' -> #( #('package') #() ).
		'run_tests' -> #( #() #('class_name' 'package' 'selector') ).
		'run_critics' -> #( #() #('class_name' 'package') ) }
]

{ #category : 'accessing' }
MCPToolSurfaceTest >> optionalOf: aTool [
	| required |
	required := self requiredOf: aTool.
	^ ((self propertiesOf: aTool) keys reject: [ :each | required includes: each ])
		asSortedCollection asArray
]

{ #category : 'accessing' }
MCPToolSurfaceTest >> propertiesOf: aTool [
	^ aTool inputSchema at: 'properties' ifAbsent: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPToolSurfaceTest >> requiredOf: aTool [
	^ (aTool inputSchema at: 'required' ifAbsent: [ #() ]) asSortedCollection asArray
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryArgumentDescribesItsTypeAndItsMeaning [
	MCPPharoTools allTools do: [ :tool |
		(self propertiesOf: tool) keysAndValuesDo: [ :argument :schema |
			| where |
			where := tool name , ' / ' , argument.
			self deny: (schema at: 'description' ifAbsent: [ '' ]) isEmpty description: where , ' has no description'.
			self
				assert: ((schema includesKey: 'type') or: [ schema includesKey: 'oneOf' ])
				description: where , ' names neither a type nor a choice' ] ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryArrayEntryKeyDescribesItsTypeAndItsMeaning [
	self class expectedArrayItemKeys keysAndValuesDo: [ :toolName :arrays |
		| properties |
		properties := (self toolNamed: toolName) outputSchema at: 'properties'.
		arrays do: [ :each |
			(((properties at: each key) at: 'items') at: 'properties') keysAndValuesDo: [ :key :schema |
				| where |
				where := toolName , ' / ' , each key , ' / ' , key.
				self assert: (schema at: 'type') equals: 'string'.
				self deny: (schema at: 'description' ifAbsent: [ '' ]) isEmpty description: where , ' has no description' ] ] ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryArrayInAnOutputSchemaDescribesOneEntry [
	self class expectedArrayItemKeys keysAndValuesDo: [ :toolName :arrays |
		| properties |
		properties := (self toolNamed: toolName) outputSchema at: 'properties'.
		arrays do: [ :each |
			| array items |
			array := properties at: each key.
			self assert: (array at: 'type') equals: 'array'.
			items := array at: 'items'.
			self assert: (items at: 'type') equals: 'object'.
			self
				assert: (items at: 'properties') keys asSortedCollection asArray
				equals: each value asSortedCollection asArray ] ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryInputSchemaIsAnObjectSchema [
	MCPPharoTools allTools do: [ :tool |
		self assert: (tool inputSchema at: 'type') equals: 'object'.
		self assert: (self propertiesOf: tool) isDictionary ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryOutputSchemaAnswersExactlyTheKeysTheTableSaysItDoes [
	self class expectedOutputSchemas keysAndValuesDo: [ :toolName :keys |
		| schema |
		schema := (self toolNamed: toolName) outputSchema.
		self assert: (schema at: 'type') equals: 'object'.
		self
			assert: (schema at: 'properties') keys asSortedCollection asArray
			equals: keys asSortedCollection asArray ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryOutputSchemaKeyDescribesItsTypeAndItsMeaning [
	self class expectedOutputSchemas keys do: [ :toolName |
		((self toolNamed: toolName) outputSchema at: 'properties') keysAndValuesDo: [ :key :schema |
			| where |
			where := toolName , ' / ' , key.
			self deny: (schema at: 'description' ifAbsent: [ '' ]) isEmpty description: where , ' has no description'.
			self assert: (schema includesKey: 'type') description: where , ' names no type' ] ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryRequiredArgumentIsOneOfTheProperties [
	MCPPharoTools allTools do: [ :tool |
		(self requiredOf: tool) do: [ :argument |
			self
				assert: ((self propertiesOf: tool) includesKey: argument)
				description: tool name , ' requires ' , argument , ' without describing it' ] ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEverySideArgumentOffersTheTwoSidesAndNothingElse [
	| tools |
	tools := MCPPharoTools allTools select: [ :each | (self propertiesOf: each) includesKey: 'side' ].
	self assert: tools size equals: 6.
	tools do: [ :tool |
		self
			assert: (((self propertiesOf: tool) at: 'side') at: 'enum')
			equals: #('instance' 'class') ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolAcceptsExactlyTheOptionalArgumentsTheTableSaysItDoes [
	self class expectedSurface keysAndValuesDo: [ :toolName :spec |
		self
			assert: (self optionalOf: (self toolNamed: toolName))
			equals: spec second asSortedCollection asArray ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolAnswersTheFourAnnotationHints [
	MCPPharoTools allTools do: [ :tool |
		self
			assert: tool annotations keys asSortedCollection asArray
			equals: #('destructiveHint' 'idempotentHint' 'openWorldHint' 'readOnlyHint') ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolCarriesATitleAndADescriptionOfItsOwn [
	MCPPharoTools allTools do: [ :tool |
		self deny: tool title isEmpty description: tool name , ' has no title'.
		self deny: tool description isEmpty description: tool name , ' has no description'.
		self deny: tool title = tool name description: tool name , ' repeats its name as its title' ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolClassAnswersItsOwnExecute [
	MCPPharoTools allTools do: [ :tool |
		self
			assert: (tool class includesSelector: #execute:)
			description: tool class name , ' leans on the block path of MCPTool' ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolClassLivesInTheToolsTag [
	MCPPharoTools allTools do: [ :tool |
		self assert: tool class package name equals: 'PharoMCP'.
		self assert: tool class packageTag name equals: 'Tools' ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testEveryToolRequiresExactlyTheTableSaysItDoes [
	self class expectedSurface keysAndValuesDo: [ :toolName :spec |
		self
			assert: (self requiredOf: (self toolNamed: toolName))
			equals: spec first asSortedCollection asArray ]
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testOnlyTheReportingToolsDeclareAnOutputSchema [
	| declaring |
	declaring := (MCPPharoTools allTools
		select: [ :each | each outputSchema notNil ]
		thenCollect: [ :each | each name ]) asSet.
	self assert: declaring equals: self class expectedOutputSchemas keys asSet
]

{ #category : 'tests' }
MCPToolSurfaceTest >> testTableNamesEveryToolAndNoOther [
	self
		assert: (MCPPharoTools allTools collect: [ :each | each name ]) asSet
		equals: self class expectedSurface keys asSet
]

{ #category : 'accessing' }
MCPToolSurfaceTest >> toolNamed: aName [
	^ MCPPharoTools allTools detect: [ :each | each name = aName ]
]
