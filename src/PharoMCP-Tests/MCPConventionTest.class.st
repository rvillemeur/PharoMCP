"
Holds the PharoMCP packages to the conventions this project works by, so a method that breaks one fails here rather than in a reader's browser.

Covers: every class carries a comment and no comment holds a line feed; every <sampleInstance> example is class side and unary; every inspector view is a keyword selector taking the presenter builder; and the protocol revision strings live in one method.
"
Class {
	#name : 'MCPConventionTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
MCPConventionTest >> exampleClasses [

	^ { MCPServerExamples. MCPToolExamples. MCPRequestProcessorExamples.
		MCPLoggerExamples. MCPLogEntryExamples }
]

{ #category : 'helpers' }
MCPConventionTest >> fingerprintOf: anObject [

	"What a view must leave alone. printString covers the scalars; the two collections a view
	 is most likely to add to are read by size, because printString of a logger says nothing
	 about how many entries it holds."

	^ {
		anObject printString.
		(anObject respondsTo: #entries) ifTrue: [ anObject entries size ] ifFalse: [ nil ].
		(anObject respondsTo: #tools) ifTrue: [ anObject tools size ] ifFalse: [ nil ] }
]

{ #category : 'helpers' }
MCPConventionTest >> projectClasses [

	^ self projectPackages flatCollect: [ :each | each definedClasses ]
]

{ #category : 'helpers' }
MCPConventionTest >> projectMethods [

	^ self projectPackages flatCollect: [ :each | each methods ]
]

{ #category : 'helpers' }
MCPConventionTest >> projectPackages [

	^ #( 'PharoMCP' 'PharoMCP-Tests' 'PharoMCP-Examples' ) collect: [ :each |
		Smalltalk organization packageNamed: each ]
]

{ #category : 'helpers' }
MCPConventionTest >> subjectsWithViews [

	"Each association is a subject and the object an inspector of it is opened on. The class
	 side of a subject is a subject too, because a view explaining a rule the whole hierarchy
	 keeps belongs there."

	^ { MCPServer -> MCPServerExamples server.
		MCPRequestProcessor -> MCPRequestProcessorExamples processor.
		MCPTool -> MCPToolExamples annotatedTool.
		MCPLogger -> MCPLoggerExamples logger.
		MCPLogEntry -> MCPLogEntryExamples toolCallEntry.
		MCPLogEntry class -> MCPLogEntry.
		MCPPharoTools class -> MCPPharoTools.
		MCPTestResult -> MCPPharoToolsExamples testResult }
]

{ #category : 'tests' }
MCPConventionTest >> testBaselineDeclaresTheExpectedGroups [

	| spec |
	spec := BaselineOfPharoMCP project version spec.
	self
		assert: (spec packages collect: [ :each | each name ]) asSet
		equals: #( 'PharoMCP' 'PharoMCP-Tests' 'PharoMCP-Examples' ) asSet.
	self
		assert: (spec groups collect: [ :each | each name ]) asSet
		equals: #( 'default' 'tests' 'examples' 'dev' ) asSet
]

{ #category : 'tests' }
MCPConventionTest >> testClearAnswersTheLogger [

	"A clear that answers its last expression answers the collection it just built, which a
	 cascade would then keep sending to."

	| logger |
	logger := MCPLoggerExamples logger.
	self assert: logger clear identicalTo: logger.
	self assert: logger entries isEmpty.
	self assert: MCPNullLogger new clear class equals: MCPNullLogger
]

{ #category : 'tests' }
MCPConventionTest >> testDefaultGroupLoadsNoTestPackage [

	"A client loading the server has no use for the test or example packages, and MuTalk is a
	 development tool."

	| spec default |
	spec := BaselineOfPharoMCP project version spec.
	default := spec groups detect: [ :each | each name = 'default' ].
	self assert: default includes asSet equals: #( 'PharoMCP' ) asSet
]

{ #category : 'tests' }
MCPConventionTest >> testEntryClassRegistryHoldsEverySubclass [

	"The registry is what makes each entry subclass referenced from code; a subclass left out
	 of it would be picked by nothing and read by nobody."

	self
		assert: MCPLogEntry entryClasses asSet
		equals: MCPLogEntry subclasses asSet.
	self deny: (MCPLogEntry entryClasses includes: MCPLogEntry)
]

{ #category : 'tests' }
MCPConventionTest >> testEveryClassCarriesACommentWithoutLineFeeds [

	self projectClasses do: [ :each |
		| comment |
		comment := each comment.
		self deny: (comment isNil or: [ comment isEmpty ]) description: each name , ' has no class comment'.
		self deny: (comment includes: Character lf) description: each name , ' has a line feed in its class comment' ]
]

{ #category : 'tests' }
MCPConventionTest >> testEveryExampleIsClassSideUnaryAndTagged [

	| examples |
	examples := self projectMethods select: [ :each |
		each pragmas anySatisfy: [ :pragma | pragma selector = #sampleInstance ] ].
	self deny: examples isEmpty.
	examples do: [ :each |
		self assert: each methodClass isClassSide description: each printString , ' is not class side'.
		self assert: each numArgs = 0 description: each printString , ' takes an argument'.
		self
			assert: each methodClass instanceSide package name = 'PharoMCP-Examples'
			description: each printString , ' is not in the examples package' ]
]

{ #category : 'tests' }
MCPConventionTest >> testEveryExampleRebuildsItsObject [

	"A reader clicks an example twice and must get a new object the second time, never a
	 cached one another window is already showing."

	self exampleClasses do: [ :each |
		(each class selectors select: [ :selector |
			(each class >> selector) pragmas anySatisfy: [ :pragma | pragma selector = #sampleInstance ] ])
			do: [ :selector |
				self
					deny: (each perform: selector) == (each perform: selector)
					description: each name , ' >> ' , selector , ' answers the same object twice' ] ]
]

{ #category : 'tests' }
MCPConventionTest >> testEverySubjectWithAViewOpensItOnItsExample [

	"A view that raises when a reader clicks the tab is worse than no view, so each one is
	 built here on the example the inspector would show."

	self subjectsWithViews do: [ :each |
		| views |
		views := each key selectors select: [ :selector |
			(each key >> selector) pragmas anySatisfy: [ :pragma |
				pragma selector = #inspectorPresentationOrder:title: ] ].
		self
			deny: views isEmpty
			description: each key name , ' declares no inspector view'.
		views do: [ :selector |
			| presenter |
			presenter := each value perform: selector with: SpPresenter new.
			self
				assert: presenter notNil
				description: each key name , ' >> ' , selector , ' built nothing' ] ]
]

{ #category : 'tests' }
MCPConventionTest >> testInspectorViewsTakeTheBuilder [

	| views |
	views := self projectMethods select: [ :each |
		each pragmas anySatisfy: [ :pragma | pragma selector = #inspectorPresentationOrder:title: ] ].
	self deny: views isEmpty.
	views do: [ :each |
		self
			assert: each selector last = $:
			description: each printString , ' is a unary view, which Pharo 13 refuses to open'.
		self assert: each numArgs = 1 description: each printString , ' takes more than the builder' ]
]

{ #category : 'tests' }
MCPConventionTest >> testNoInspectorViewMutatesItsSubject [

	"A reader clicking a tab must not change the object under inspection."

	self subjectsWithViews do: [ :each |
		(each key selectors select: [ :selector |
			(each key >> selector) pragmas anySatisfy: [ :pragma |
				pragma selector = #inspectorPresentationOrder:title: ] ])
			do: [ :selector |
				| before |
				before := self fingerprintOf: each value.
				each value perform: selector with: SpPresenter new.
				self
					assert: (self fingerprintOf: each value) = before
					description: each key name , ' >> ' , selector , ' changed its subject' ] ]
]

{ #category : 'tests' }
MCPConventionTest >> testProtocolRevisionStringsLiveInOneMethod [

	"A revision string written anywhere else would drift from the list the server negotiates
	 against. assumedProtocolVersion is the second home: it names the revision the
	 specification says to assume when a client sends no header."

	| writers |
	writers := (Smalltalk organization packageNamed: 'PharoMCP') methods select: [ :each |
		MCPRequestProcessor supportedProtocolVersions anySatisfy: [ :version |
			each sourceCode includesSubstring: version ] ].
	self
		assert: (writers collect: [ :each | each selector ]) asSet
		equals: (Set with: #supportedProtocolVersions with: #assumedProtocolVersion)
]

{ #category : 'tests' }
MCPConventionTest >> testWorldMenuOffersTheServerWindow [

	"MCPMenus is reached only through its <worldMenu> pragma, so nothing in the image
	 references it; this test is that reference, and it holds the menu item too."

	| builder |
	builder := PragmaMenuBuilder new.
	MCPMenus buildWorldMenu: builder.
	self
		assert: (builder menuEntitled: #PharoMCP) notNil
		description: 'the world menu carries no PharoMCP group'.
	self
		assert: ((MCPMenus class >> #buildWorldMenu:) sourceCode includesSubstring: 'MCPServerPresenter open')
		description: 'the menu item no longer opens the server window'
]
