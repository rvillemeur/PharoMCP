"
I call each tool the way a client does -- through call: with a dictionary -- for the arguments the schema marks optional, and I pin what the tool does when they are absent: which side it works on, which superclass a new class gets, which protocol a compiled method lands in, whether a search is case sensitive, and which of two alternative arguments wins. I build a scratch package of my own in setUp and remove it in tearDown, so nothing I create reaches the repository packages.
"
Class {
	#name : 'MCPToolArgumentDefaultsTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'calling' }
MCPToolArgumentDefaultsTest >> call: aToolName with: anArgumentArray [
	"Answer what the named tool answers for the given argument pairs, the way a client reaches it."

	| tool |
	tool := MCPPharoTools allTools detect: [ :each | each name = aToolName ].
	^ tool call: (Dictionary newFrom: anArgumentArray)
]

{ #category : 'calling' }
MCPToolArgumentDefaultsTest >> compileOnSubject: aSource [
	"Compile through the tool with no side argument, which is what these tests are about."

	^ self call: 'compile_method' with: { 'class_name' -> self subjectName. 'source' -> aSource }
]

{ #category : 'calling' }
MCPToolArgumentDefaultsTest >> compileOnSubjectClassSide: aSource [
	^ self call: 'compile_method' with: { 'class_name' -> self subjectName. 'side' -> 'class'. 'source' -> aSource }
]

{ #category : 'calling' }
MCPToolArgumentDefaultsTest >> methodAnswering: aLiteralSource [
	"Source of a unary method named answerTwo answering the given literal."

	^ 'answerTwo' , String cr , '	^ ' , aLiteralSource
]

{ #category : 'accessing' }
MCPToolArgumentDefaultsTest >> sandboxPackage [
	"The scratch package the sandbox classes live in, outside every repository package."

	^ 'MCPToolArgumentDefaults-Sandbox'
]

{ #category : 'running' }
MCPToolArgumentDefaultsTest >> setUp [
	super setUp.
	MCPPharoTools createPackage: self sandboxPackage.
	MCPPharoTools
		createClass: self subjectName
		superclass: 'Object'
		instanceVariables: #()
		package: self sandboxPackage.
	MCPPharoTools
		createClass: self targetName
		superclass: 'Object'
		instanceVariables: #()
		package: self sandboxPackage
]

{ #category : 'accessing' }
MCPToolArgumentDefaultsTest >> subjectName [
	^ 'MCPSandboxSubject'
]

{ #category : 'accessing' }
MCPToolArgumentDefaultsTest >> targetName [
	^ 'MCPSandboxTarget'
]

{ #category : 'running' }
MCPToolArgumentDefaultsTest >> tearDown [
	"Remove whatever the sandbox holds rather than the names setUp created, and then any class
	left behind under the sandbox prefix: removing a package moves a class it still holds to
	the unpackaged package instead of deleting it."

	(Smalltalk packageOrganizer packageNamed: self sandboxPackage ifAbsent: [ nil ]) ifNotNil: [ :package |
		package definedClasses copy do: [ :each | each removeFromSystem ].
		package removeFromSystem ].
	((Smalltalk globals keys select: [ :each | each beginsWith: 'MCPSandbox' ]) collect: [ :each |
		Smalltalk globals at: each ]) do: [ :each | each removeFromSystem ].
	super tearDown
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testClassCommentWithoutACommentReadsIt [
	self call: 'class_comment' with: { 'class_name' -> self subjectName. 'comment' -> 'A sandbox subject.' }.
	self
		assert: ((self call: 'class_comment' with: { 'class_name' -> self subjectName })
			includesSubstring: 'A sandbox subject.')
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testCompileMethodWithoutProtocolLandsInAsYetUnclassified [
	self compileOnSubject: (self methodAnswering: '2').
	self
		assert: ((Smalltalk at: self subjectName asSymbol) >> #answerTwo) protocolName
		equals: 'as yet unclassified'
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testCompileMethodWithoutSideCompilesOnTheInstanceSide [
	| subject |
	subject := Smalltalk at: self subjectName asSymbol.
	self compileOnSubject: (self methodAnswering: '2').
	self assert: (subject includesSelector: #answerTwo).
	self deny: (subject class includesSelector: #answerTwo)
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testCreateClassWithoutSuperclassOrVariablesSubclassesObjectWithNone [
	| created |
	self call: 'class_create' with: { 'class_name' -> 'MCPSandboxPlain'. 'package' -> self sandboxPackage }.
	created := Smalltalk at: #MCPSandboxPlain.
	self assert: created superclass equals: Object.
	self assert: created instVarNames isEmpty.
	self assert: created package name equals: self sandboxPackage
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testDeleteMethodWithoutSideDeletesFromTheInstanceSide [
	| subject |
	subject := Smalltalk at: self subjectName asSymbol.
	self compileOnSubject: (self methodAnswering: '2').
	self compileOnSubjectClassSide: (self methodAnswering: '2').
	self call: 'delete_method' with: { 'class_name' -> self subjectName. 'selector' -> 'answerTwo' }.
	self deny: (subject includesSelector: #answerTwo).
	self assert: (subject class includesSelector: #answerTwo)
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testListClassesWithAnEmptyPatternAsksForOne [
	"The schema makes pattern required, so the processor rejects its absence before the tool
	runs; an empty string reaches the tool, and the tool refuses to list the whole image."

	self
		assert: ((self call: 'list_classes' with: { 'pattern' -> '' })
			includesSubstring: 'non-empty pattern')
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testListMethodsWithoutSideListsTheInstanceSide [
	| listed |
	self compileOnSubject: (self methodAnswering: '2').
	self compileOnSubjectClassSide: ('buildOne' , String cr , '	^ self new').
	listed := self call: 'list_methods' with: { 'className' -> self subjectName }.
	self assert: (listed includesSubstring: 'answerTwo').
	self deny: (listed includesSubstring: 'buildOne')
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testListPackagesWithoutPatternListsThemAll [
	"Without a pattern the tool reaches every package of the image and says how many it caps
	the listing at; with one it lists the matches alone."

	| all filtered |
	all := self call: 'list_packages' with: { }.
	filtered := self call: 'list_packages' with: { 'pattern' -> 'MCPToolArgumentDefaults' }.
	self assert: (all includesSubstring: 'Showing first 200 of ').
	self assert: (all includesSubstring: 'AST-Core').
	self assert: (filtered includesSubstring: self sandboxPackage).
	self deny: (filtered includesSubstring: 'AST-Core')
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testMethodSourceWithoutSideReadsTheInstanceSide [
	self compileOnSubject: (self methodAnswering: '2').
	self compileOnSubjectClassSide: (self methodAnswering: '3').
	self
		assert: ((self call: 'method_source' with: { 'className' -> self subjectName. 'methodName' -> 'answerTwo' })
			includesSubstring: '^ 2')
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testMoveMethodWithoutSideMovesFromTheInstanceSide [
	| subject target |
	subject := Smalltalk at: self subjectName asSymbol.
	target := Smalltalk at: self targetName asSymbol.
	self compileOnSubject: (self methodAnswering: '2').
	self compileOnSubjectClassSide: (self methodAnswering: '2').
	self
		call: 'method_move'
		with: { 'class_name' -> self subjectName. 'selector' -> 'answerTwo'. 'target_class' -> self targetName }.
	self assert: (target includesSelector: #answerTwo).
	self deny: (subject includesSelector: #answerTwo).
	self assert: (subject class includesSelector: #answerTwo)
]

{ #category : 'tests - side' }
MCPToolArgumentDefaultsTest >> testRenameMethodWithoutSideRenamesOnTheInstanceSide [
	| subject |
	subject := Smalltalk at: self subjectName asSymbol.
	self compileOnSubject: (self methodAnswering: '2').
	self compileOnSubjectClassSide: (self methodAnswering: '2').
	self
		call: 'method_rename'
		with: { 'class_name' -> self subjectName. 'old_selector' -> 'answerTwo'. 'new_selector' -> 'answerTwoAgain' }.
	self assert: (subject includesSelector: #answerTwoAgain).
	self deny: (subject includesSelector: #answerTwo).
	self assert: (subject class includesSelector: #answerTwo)
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testSearchSourceSearchesThePackageWhenBothArgumentsArrive [
	"package wins over class_name: the pattern lives only in the sandbox, so a search driven by
	class_name would answer no match at all."

	self compileOnSubject: (self methodAnswering: '''needle''').
	self
		assert: ((self call: 'search_source'
			with: { 'pattern' -> 'needle'. 'class_name' -> 'MCPTool'. 'package' -> self sandboxPackage })
				includesSubstring: self subjectName , ' >> #answerTwo')
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testSearchSourceWithCaseSensitiveHonoursCase [
	self compileOnSubject: (self methodAnswering: '''NEEDLE''').
	self
		deny: ((self call: 'search_source'
			with: { 'pattern' -> 'needle'. 'class_name' -> self subjectName. 'case_sensitive' -> true })
				includesSubstring: 'answerTwo')
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testSearchSourceWithNeitherClassNorPackageSaysWhatIsMissing [
	[ self call: 'search_source' with: { 'pattern' -> 'needle' } ]
		on: MCPToolError
		do: [ :error |
			self assert: error messageText equals: 'provide class_name or package'.
			^ self ].
	self fail: 'search_source answered instead of signalling'
]

{ #category : 'tests - defaults' }
MCPToolArgumentDefaultsTest >> testSearchSourceWithoutCaseSensitiveIgnoresCase [
	self compileOnSubject: (self methodAnswering: '''NEEDLE''').
	self
		assert: ((self call: 'search_source' with: { 'pattern' -> 'needle'. 'class_name' -> self subjectName })
			includesSubstring: 'answerTwo')
]
