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
MCPConventionTest >> testDefaultGroupLoadsNoTestPackage [

	"A client loading the server has no use for the test or example packages, and MuTalk is a
	 development tool."

	| spec default |
	spec := BaselineOfPharoMCP project version spec.
	default := spec groups detect: [ :each | each name = 'default' ].
	self assert: default includes asSet equals: #( 'PharoMCP' ) asSet
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
