"
Holds MCPTool to what it emits to a client and to the required arguments it checks before its handler runs.
"
Class {
	#name : 'MCPToolTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
MCPToolTest >> plainTool [
	"A tool built the way a client builds one: a block handler and no optional field set."

	^ MCPTool
		name: 'plain'
		description: 'A tool with nothing optional set'
		schema: Dictionary new
		handler: [ :arguments | 'ok' ]
]

{ #category : 'helpers' }
MCPToolTest >> presentationArgumentsOf: aCompiledMethod [
	"The order and the title the inspector reads off a view, as the pragma states them."

	^ (aCompiledMethod pragmaAt: #inspectorPresentationOrder:title:) arguments
]

{ #category : 'helpers' }
MCPToolTest >> presenterBuilder [
	"The builder the inspector hands a view. Building a presenter opens no window."

	^ SpPresenterBuilder newApplication: SpApplication new
]

{ #category : 'tests - schema builders' }
MCPToolTest >> testArrayOfMessagesSchemaDescribesSelectorAndMessage [
	| schema items properties |
	schema := self plainTool schemaArrayOfMessagesDescribedAs: 'The tests that failed'.
	self assert: schema keys asSortedCollection asArray equals: #( 'description' 'items' 'type' ).
	self assert: (schema at: 'type') equals: 'array'.
	self assert: (schema at: 'description') equals: 'The tests that failed'.
	items := schema at: 'items'.
	self assert: items keys asSortedCollection asArray equals: #( 'properties' 'type' ).
	self assert: (items at: 'type') equals: 'object'.
	properties := items at: 'properties'.
	self assert: properties keys asSortedCollection asArray equals: #( 'message' 'selector' ).
	self assert: ((properties at: 'selector') at: 'type') equals: 'string'.
	self assert: ((properties at: 'message') at: 'type') equals: 'string'.
	self deny: ((properties at: 'selector') at: 'description') equals: ((properties at: 'message') at: 'description')
]

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

{ #category : 'tests - as dictionary' }
MCPToolTest >> testAsDictionaryCarriesEachOptionalFieldOnItsOwn [
	"Three separate guards answer for the three optional fields, so each one is set alone here:
	 a guard reading the wrong field passes when all three are set together."

	self
		assert: (self plainTool title: 'Only a title'; yourself) asDictionary keys asSortedCollection asArray
		equals: #( 'description' 'inputSchema' 'name' 'title' ).
	self
		assert: (self plainTool readOnly; yourself) asDictionary keys asSortedCollection asArray
		equals: #( 'annotations' 'description' 'inputSchema' 'name' ).
	self
		assert: (self plainTool outputSchema: Dictionary new; yourself) asDictionary keys asSortedCollection asArray
		equals: #( 'description' 'inputSchema' 'name' 'outputSchema' )
]

{ #category : 'tests - as dictionary' }
MCPToolTest >> testAsDictionaryCarriesEveryOptionalFieldWhenEachIsSet [
	| tool annotations outputSchema dictionary |
	annotations := Dictionary new at: 'readOnlyHint' put: true; yourself.
	outputSchema := Dictionary new at: 'type' put: 'object'; yourself.
	tool := self plainTool
		title: 'Plain tool';
		annotations: annotations;
		outputSchema: outputSchema;
		yourself.
	dictionary := tool asDictionary.
	self
		assert: dictionary keys asSortedCollection asArray
		equals: #( 'annotations' 'description' 'inputSchema' 'name' 'outputSchema' 'title' ).
	self assert: (dictionary at: 'name') equals: 'plain'.
	self assert: (dictionary at: 'description') equals: 'A tool with nothing optional set'.
	self assert: (dictionary at: 'inputSchema') equals: tool inputSchema.
	self assert: (dictionary at: 'title') equals: 'Plain tool'.
	self assert: (dictionary at: 'annotations') equals: annotations.
	self assert: (dictionary at: 'outputSchema') equals: outputSchema
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

{ #category : 'tests - views' }
MCPToolTest >> testAsSentViewShowsTheWholeToolAndNotOnlyItsSchema [
	| tool text |
	tool := self plainTool title: 'Plain tool'; yourself.
	text := (tool inspectionAsSentToClient: self presenterBuilder) text.
	self assert: (text includesSubstring: 'Plain tool').
	self assert: (text includesSubstring: 'plain').
	self assert: (text includesSubstring: 'inputSchema')
]

{ #category : 'tests - annotations' }
MCPToolTest >> testHintsCarryTheFourFlagsTheCallerAsksFor [
	"Each flag is read back on its own, so a builder that answers one flag in another's place
	 does not pass."

	| hints |
	hints := self plainTool hintsReadOnly: true destructive: false idempotent: false.
	self
		assert: hints keys asSortedCollection asArray
		equals: #( 'destructiveHint' 'idempotentHint' 'openWorldHint' 'readOnlyHint' ).
	self assert: (hints at: 'readOnlyHint').
	self deny: (hints at: 'destructiveHint').
	self deny: (hints at: 'idempotentHint').
	self deny: (hints at: 'openWorldHint').
	hints := self plainTool hintsReadOnly: false destructive: true idempotent: true.
	self deny: (hints at: 'readOnlyHint').
	self assert: (hints at: 'destructiveHint').
	self assert: (hints at: 'idempotentHint').
	self deny: (hints at: 'openWorldHint')
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

{ #category : 'tests - schema builders' }
MCPToolTest >> testObjectSchemaCarriesTypePropertiesAndRequired [
	| schema |
	schema := self plainTool
		schemaWithProperties: { 'code' -> 'the code property'. 'side' -> 'the side property' }
		required: #( 'code' ).
	self assert: schema keys asSortedCollection asArray equals: #( 'properties' 'required' 'type' ).
	self assert: (schema at: 'type') equals: 'object'.
	self assert: (schema at: 'required') equals: #( 'code' ).
	self assert: (schema at: 'properties') keys asSortedCollection asArray equals: #( 'code' 'side' ).
	self assert: ((schema at: 'properties') at: 'code') equals: 'the code property'
]

{ #category : 'tests - views' }
MCPToolTest >> testRequiredArgumentsOfJoinsTheNamesSorted [
	self
		assert: (MCPTool requiredArgumentsOf: MCPMoveMethodTool)
		equals: 'class_name selector target_class'.
	self assert: (MCPTool requiredArgumentsOf: MCPEvaluateTool) equals: 'code'.
	self assert: (MCPTool requiredArgumentsOf: MCPRunTestsTool) equals: ''
]

{ #category : 'tests - schema builders' }
MCPToolTest >> testSchemaPropertyCarriesItsTypeAndDescription [
	| property |
	property := self plainTool schemaPropertyOfType: 'integer' describedAs: 'How many'.
	self assert: property keys asSortedCollection asArray equals: #( 'description' 'type' ).
	self assert: (property at: 'type') equals: 'integer'.
	self assert: (property at: 'description') equals: 'How many'
]

{ #category : 'tests - schema builders' }
MCPToolTest >> testSchemaPropertyOneOfCarriesTheAllowedValues [
	| property |
	property := self plainTool schemaPropertyOneOf: #( 'red' 'green' ) describedAs: 'Which colour'.
	self assert: property keys asSortedCollection asArray equals: #( 'description' 'enum' 'type' ).
	self assert: (property at: 'type') equals: 'string'.
	self assert: (property at: 'enum') equals: #( 'red' 'green' ).
	self assert: (property at: 'description') equals: 'Which colour'
]

{ #category : 'tests - views' }
MCPToolTest >> testSchemaViewShowsTheInputSchemaAlone [
	| tool text |
	tool := self plainTool
		title: 'Plain tool';
		inputSchema: (Dictionary new at: 'type' put: 'object'; yourself);
		yourself.
	text := (tool inspectionSchema: self presenterBuilder) text.
	self assert: (text includesSubstring: '"type"').
	self assert: (text includesSubstring: 'object').
	self deny: (text includesSubstring: 'Plain tool')
]

{ #category : 'tests - schema builders' }
MCPToolTest >> testSideSchemaPropertyOffersInstanceThenClass [
	"The order is part of the published surface: a client shows the first value as the default."

	| property |
	property := self plainTool schemaSideProperty.
	self assert: (property at: 'enum') equals: #( 'instance' 'class' ).
	self assert: (property at: 'type') equals: 'string'.
	self assert: ((property at: 'description') includesSubstring: 'Defaults to instance')
]

{ #category : 'tests - as dictionary' }
MCPToolTest >> testStructuredContentNeedsBothAnOutputSchemaAndADictionary [
	"A tool with an output schema answers a dictionary when it worked and a plain string when it
	 has an error to report, and only the dictionary goes in structuredContent."

	| plain declaring |
	plain := self plainTool.
	declaring := self plainTool outputSchema: Dictionary new; yourself.
	self deny: (plain answersStructuredContent: Dictionary new).
	self deny: (plain answersStructuredContent: 'some text').
	self assert: (declaring answersStructuredContent: Dictionary new).
	self deny: (declaring answersStructuredContent: 'some text')
]

{ #category : 'tests - annotations' }
MCPToolTest >> testTheThreeAnnotationShortcutsInstallTheirOwnHints [
	| tool |
	tool := self plainTool.
	self assert: tool readOnly annotations equals: tool readOnlyHints.
	self assert: tool destructive annotations equals: tool destructiveHints.
	self assert: tool additive annotations equals: tool additiveHints.
	self
		assert: (self plainTool readOnlyHint: false destructiveHint: true idempotentHint: false) annotations
		equals: tool destructiveHints
]

{ #category : 'tests - annotations' }
MCPToolTest >> testTheThreeHintSetsSayWhatTheirNamesSay [
	| tool |
	tool := self plainTool.
	self assert: (tool readOnlyHints at: 'readOnlyHint').
	self deny: (tool readOnlyHints at: 'destructiveHint').
	self assert: (tool readOnlyHints at: 'idempotentHint').
	self deny: (tool destructiveHints at: 'readOnlyHint').
	self assert: (tool destructiveHints at: 'destructiveHint').
	self deny: (tool destructiveHints at: 'idempotentHint').
	self deny: (tool additiveHints at: 'readOnlyHint').
	self deny: (tool additiveHints at: 'destructiveHint').
	self assert: (tool additiveHints at: 'idempotentHint')
]

{ #category : 'tests - views' }
MCPToolTest >> testTheThreeViewsDeclareTheirPlaceAndTitle [
	"A reader meets the schema first and the whole payload second, and the family view sits
	 beside the class itself. Each view is built before its pragma is read: MuTalk runs a mutant
	 only against the tests its coverage analysis saw execute the method, so a test that reads a
	 pragma without building the view leaves a changed title or order unnoticed."

	| tool |
	tool := self plainTool.
	tool inspectionSchema: self presenterBuilder.
	tool inspectionAsSentToClient: self presenterBuilder.
	MCPTool inspectorToolClasses: self presenterBuilder.
	self
		assert: (self presentationArgumentsOf: MCPTool >> #inspectionSchema:)
		equals: #( 0 'Schema' ).
	self
		assert: (self presentationArgumentsOf: MCPTool >> #inspectionAsSentToClient:)
		equals: #( 1 'As sent' ).
	self
		assert: (self presentationArgumentsOf: MCPTool class >> #inspectorToolClasses:)
		equals: #( 1 'Tool classes' )
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

{ #category : 'tests - views' }
MCPToolTest >> testToolClassesViewHasOneSortedRowPerToolClass [
	| table titles |
	table := MCPTool inspectorToolClasses: self presenterBuilder.
	titles := (table columns collect: [ :each | each title ]) asArray.
	self assert: titles equals: #( 'Class' 'Tool' 'Required' 'Own execute:' 'Output schema' ).
	self assert: table items asSet equals: MCPTool subclasses asSet.
	self
		assert: (table items collect: [ :each | each name ]) asArray
		equals: (table items collect: [ :each | each name ]) asSortedCollection asArray
]

{ #category : 'tests - views' }
MCPToolTest >> testToolClassesViewReadsEveryCellOffTheClassItself [
	"The row for run_tests is the one that answers yes in both of the last two columns, and
	 evaluate_pharo is the one tool whose single required argument is code."

	| table cellsFor |
	table := MCPTool inspectorToolClasses: self presenterBuilder.
	cellsFor := [ :toolClass |
		(table columns collect: [ :column | column evaluation value: toolClass ]) asArray ].
	self
		assert: (cellsFor value: MCPRunTestsTool)
		equals: #( 'MCPRunTestsTool' 'run_tests' '' 'yes' 'yes' ).
	self
		assert: (cellsFor value: MCPEvaluateTool)
		equals: #( 'MCPEvaluateTool' 'evaluate_pharo' 'code' 'yes' '' )
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

{ #category : 'tests - views' }
MCPToolTest >> testYesWhenAnswersYesOrNothing [
	"A cell says yes or stays empty, because a column of yeses reads worse with a false in it."

	self assert: (MCPTool yesWhen: true) equals: 'yes'.
	self assert: (MCPTool yesWhen: false) equals: ''
]
