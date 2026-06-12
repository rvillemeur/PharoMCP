Class {
	#name : 'MCPPharoToolsRunningTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testClassCommentToolHasCorrectName [
	self assert: MCPPharoTools classCommentTool name equals: 'class_comment'
]

{ #category : 'tests - classHierarchy' }
MCPPharoToolsRunningTest >> testClassHierarchyOfLeafShowsNone [
	| r |
	r := MCPPharoTools classHierarchyOf: 'MCPPharoToolsRunningTest'.
	self assert: (r includesSubstring: '(none)')
]

{ #category : 'tests - classHierarchy' }
MCPPharoToolsRunningTest >> testClassHierarchyOfShowsSubclasses [
	| r |
	r := MCPPharoTools classHierarchyOf: 'SequenceableCollection'.
	self assert: (r includesSubstring: 'Direct subclasses').
	self assert: (r includesSubstring: 'OrderedCollection')
]

{ #category : 'tests - classHierarchy' }
MCPPharoToolsRunningTest >> testClassHierarchyOfUnknown [
	| r |
	r := MCPPharoTools classHierarchyOf: 'NoSuchClassXYZ'.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - classHierarchy' }
MCPPharoToolsRunningTest >> testClassHierarchyOfValid [
	| r |
	r := MCPPharoTools classHierarchyOf: 'OrderedCollection'.
	self assert: (r includesSubstring: 'Superclass chain:').
	self assert: (r includesSubstring: 'OrderedCollection')
]

{ #category : 'tests - collectCritiques' }
MCPPharoToolsRunningTest >> testCollectCritiquesForClassReturnsCollection [
	| result |
	result := MCPPharoTools collectCritiquesForClass: MCPPharoTools.
	self assert: (result isKindOf: Collection)
]

{ #category : 'tests - collectCritiques' }
MCPPharoToolsRunningTest >> testCollectCritiquesIncludesBothSides [
	| instanceOnly combined |
	instanceOnly := ReCriticEngine critiquesOf: MCPPharoTools.
	combined := MCPPharoTools collectCritiquesForClass: MCPPharoTools.
	self assert: combined size >= instanceOnly size
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodClassSide [
	| result |
	result := MCPPharoTools compileMethod: 'compileTestClassMethod ^ 77'
		onClass: 'MCPPharoToolsRunningTest'
		side: 'class'
		classified: 'private'.
	self assert: (result includesSubstring: 'class').
	self assert: MCPPharoToolsRunningTest compileTestClassMethod equals: 77.
	MCPPharoToolsRunningTest class removeSelector: #compileTestClassMethod
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodNormalisesLF [
	| lfSource result |
	lfSource := 'lfTestMethod
	^ 55'.
	result := MCPPharoTools compileMethod: lfSource
		onClass: 'MCPPharoToolsRunningTest'
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Compiled:').
	self assert: MCPPharoToolsRunningTest new lfTestMethod equals: 55.
	MCPPharoToolsRunningTest removeSelector: #lfTestMethod
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodSuccess [
	| result |
	result := MCPPharoTools compileMethod: 'compileTestMethod ^ 99'
		onClass: 'MCPPharoToolsRunningTest'
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Compiled:').
	self assert: (result includesSubstring: 'compileTestMethod').
	self assert: MCPPharoToolsRunningTest new compileTestMethod equals: 99.
	MCPPharoToolsRunningTest removeSelector: #compileTestMethod
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodSyntaxError [
	| result |
	result := MCPPharoTools compileMethod: 'this is not valid smalltalk !!!'
		onClass: 'MCPPharoToolsRunningTest'
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Error')
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodToolHasCorrectName [
	| tool |
	tool := MCPPharoTools compileMethodTool.
	self assert: tool name equals: 'compile_method'
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [:t | t name = 'compile_method'])
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodToolSchemaRequiresClassAndSource [
	| tool schema required |
	tool := MCPPharoTools compileMethodTool.
	schema := tool inputSchema.
	required := schema at: 'required'.
	self assert: (required includes: 'class_name').
	self assert: (required includes: 'source')
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodUnknownClass [
	| result |
	result := MCPPharoTools compileMethod: 'foo ^ 1'
		onClass: 'NoSuchClassXYZ'
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassAlreadyExists [
	| result |
	result := MCPPharoTools
		createClass: 'Object'
		superclass: 'Object'
		instanceVariables: #()
		package: 'PharoMCP-Tests'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'already exists')
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassNoInstVars [
	| result |
	result := MCPPharoTools createClass: 'TestCreateMCPXYZ' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	self assert: (result beginsWith: 'Created:').
	self assert: TestCreateMCPXYZ instVarNames isEmpty.
	Smalltalk globals removeClassNamed: #TestCreateMCPXYZ
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassNoInstanceVariables [
	| result className |
	className := 'MCPTestTempClassCCC'.
	[ result := MCPPharoTools
		createClass: className
		superclass: 'Object'
		instanceVariables: #()
		package: 'PharoMCP-Tests'.
	self assert: (result beginsWith: 'Created:').
	self assert: (result includesSubstring: '0 instance variables') ]
	ensure: [ (Smalltalk globals includesKey: className asSymbol) ifTrue: [
		(Smalltalk globals at: className asSymbol) removeFromSystem ] ]
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassSuccess [
	| result className |
	className := 'MCPTestTempClassAAA'.
	[ result := MCPPharoTools
		createClass: className
		superclass: 'Object'
		instanceVariables: #('foo' 'bar')
		package: 'PharoMCP-Tests'.
	self assert: (result beginsWith: 'Created:').
	self assert: (result includesSubstring: className).
	self assert: (result includesSubstring: '2 instance variables') ]
	ensure: [ (Smalltalk globals includesKey: className asSymbol) ifTrue: [
		(Smalltalk globals at: className asSymbol) removeFromSystem ] ]
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassToolHasCorrectName [
	self assert: MCPPharoTools createClassTool name equals: 'class_create'
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'class_create' ])
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassUnknownSuperclass [
	| result |
	result := MCPPharoTools
		createClass: 'MCPTestTempClassBBB'
		superclass: 'NoSuchSuperclassXYZ'
		instanceVariables: #()
		package: 'PharoMCP-Tests'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchSuperclassXYZ')
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodClassSide [
	| result |
	MCPPharoToolsRunningTest class compile: 'tempDeleteMeClass ^ 0' classified: 'private'.
	result := MCPPharoTools deleteMethod: 'tempDeleteMeClass' fromClass: 'MCPPharoToolsRunningTest' side: 'class'.
	self assert: (result includesSubstring: 'class').
	self deny: (MCPPharoToolsRunningTest class includesSelector: #tempDeleteMeClass)
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodSuccess [
	| result |
	MCPPharoToolsRunningTest compile: 'tempDeleteMe ^ 0' classified: 'private'.
	result := MCPPharoTools deleteMethod: 'tempDeleteMe' fromClass: 'MCPPharoToolsRunningTest' side: 'instance'.
	self assert: (result beginsWith: 'Deleted:').
	self deny: (MCPPharoToolsRunningTest includesSelector: #tempDeleteMe)
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodToolHasCorrectName [
	self assert: MCPPharoTools deleteMethodTool name equals: 'delete_method'
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [:t | t name = 'delete_method'])
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodUnknownClass [
	| result |
	result := MCPPharoTools deleteMethod: 'foo' fromClass: 'NoSuchClassXYZ' side: 'instance'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodUnknownSelector [
	| result |
	result := MCPPharoTools deleteMethod: 'noSuchSelectorXYZ' fromClass: 'MCPPharoToolsRunningTest' side: 'instance'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'noSuchSelectorXYZ')
]

{ #category : 'tests - findImplementors' }
MCPPharoToolsRunningTest >> testFindImplementorsOfEmptySelector [
	| r |
	r := MCPPharoTools findImplementorsOf: ''.
	self assert: (r beginsWith: 'Error')
]

{ #category : 'tests - findImplementors' }
MCPPharoToolsRunningTest >> testFindImplementorsOfUnknownSelector [
	| r |
	r := MCPPharoTools findImplementorsOf: 'noSuchMethodXYZ99'.
	self assert: (r includesSubstring: 'No implementors found')
]

{ #category : 'tests - findImplementors' }
MCPPharoToolsRunningTest >> testFindImplementorsOfValidSelector [
	| r |
	r := MCPPharoTools findImplementorsOf: 'printOn:'.
	self deny: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'implementors of #printOn:')
]

{ #category : 'tests - findSenders' }
MCPPharoToolsRunningTest >> testFindSendersOfEmptySelector [
	| r |
	r := MCPPharoTools findSendersOf: ''.
	self assert: (r beginsWith: 'Error')
]

{ #category : 'tests - findSenders' }
MCPPharoToolsRunningTest >> testFindSendersOfUnknownSelector [
	| r |
	r := MCPPharoTools findSendersOf: 'noSuchMethodXYZ99'.
	self assert: (r includesSubstring: 'No senders found')
]

{ #category : 'tests - findSenders' }
MCPPharoToolsRunningTest >> testFindSendersOfValidSelector [

	| r |
	r := MCPPharoTools findSendersOf: 'printOn:'.
	self deny: (r beginsWith: 'Error').
	self assert: r isNotEmpty
]

{ #category : 'tests - formatCritiques' }
MCPPharoToolsRunningTest >> testFormatCritiquesEmpty [
	| r |
	r := MCPPharoTools formatCritiques: OrderedCollection new forName: 'MyClass'.
	self assert: (r includesSubstring: 'No critiques found for: MyClass')
]

{ #category : 'tests - formatResult' }
MCPPharoToolsRunningTest >> testFormatResultNilSelector [
	| result r |
	result := MCPTestResult new.
	r := MCPPharoTools formatResult: result forName: 'MyClass' selector: nil duration: 42.
	self assert: (r includesSubstring: 'Ran').
	self assert: (r includesSubstring: 'MyClass').
	self assert: (r includesSubstring: 'passed').
	self assert: (r includesSubstring: '42 ms')
]

{ #category : 'tests - formatResult' }
MCPPharoToolsRunningTest >> testFormatResultWithSelector [
	| result r |
	result := MCPTestResult new.
	r := MCPPharoTools formatResult: result forName: 'MyClass' selector: 'myTest' duration: 0.
	self assert: (r includesSubstring: 'MyClass').
	self assert: (r includesSubstring: 'myTest')
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testGetClassCommentNoComment [
	| r |
	r := MCPPharoTools getClassComment: 'MCPPharoToolsRunningTest'.
	self assert: r equals: '(no comment)'
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testGetClassCommentReturnsComment [
	| r |
	r := MCPPharoTools getClassComment: 'MCPServer'.
	self deny: (r beginsWith: 'Error')
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testGetClassCommentUnknownClass [
	| r |
	r := MCPPharoTools getClassComment: 'NoSuchClassXYZ'.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - listMethods' }
MCPPharoToolsRunningTest >> testListMethodsClassSideIncludesProtocol [
	| tool result |
	tool := MCPPharoTools listMethodsTool.
	result := tool handler value: (Dictionary new
		at: 'className' put: 'MCPPharoTools';
		at: 'side' put: 'class';
		yourself).
	self assert: (result includesSubstring: ' | ').
	self deny: (result beginsWith: 'Error')
]

{ #category : 'tests - listMethods' }
MCPPharoToolsRunningTest >> testListMethodsIncludesProtocol [
	| tool result |
	tool := MCPPharoTools listMethodsTool.
	result := tool handler value: (Dictionary new at: 'className' put: 'MCPTool'; yourself).
	self assert: (result includesSubstring: ' | ').
	self assert: (result includesSubstring: 'accessing')
]

{ #category : 'tests - listMethods' }
MCPPharoToolsRunningTest >> testListMethodsSortedByProtocolThenSelector [
	| tool result lines descIdx nameIdx |
	tool := MCPPharoTools listMethodsTool.
	result := tool handler value: (Dictionary new at: 'className' put: 'MCPTool'; yourself).
	lines := result lines reject: [ :l | l isEmpty ].
	self assert: lines size > 1.
	descIdx := lines indexOf: 'accessing | description'.
	nameIdx := lines indexOf: 'accessing | name'.
	self assert: descIdx > 0.
	self assert: nameIdx > 0.
	self assert: descIdx < nameIdx
]

{ #category : 'tests - listMethods' }
MCPPharoToolsRunningTest >> testListMethodsToolHasCorrectName [
	self assert: MCPPharoTools listMethodsTool name equals: 'list_methods'
]

{ #category : 'tests - removeClass' }
MCPPharoToolsRunningTest >> testRemoveClassSuccess [
	| result className |
	className := 'MCPTestTempRemoveDDD'.
	MCPPharoTools createClass: className superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	result := MCPPharoTools removeClass: className.
	self assert: (result beginsWith: 'Removed:').
	self assert: (result includesSubstring: className).
	self deny: (Smalltalk globals includesKey: className asSymbol)
]

{ #category : 'tests - removeClass' }
MCPPharoToolsRunningTest >> testRemoveClassToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'class_remove' ])
]

{ #category : 'tests - removeClass' }
MCPPharoToolsRunningTest >> testRemoveClassUnknown [
	| result |
	result := MCPPharoTools removeClass: 'NoSuchClassXYZ'.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - removeClass' }
MCPPharoToolsRunningTest >> testRemoveClassWithSubclassesFails [
	| parent child result |
	parent := 'MCPTestTempParentEEE'.
	child := 'MCPTestTempChildEEE'.
	[ MCPPharoTools createClass: parent superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	MCPPharoTools createClass: child superclass: parent instanceVariables: #() package: 'PharoMCP-Tests'.
	result := MCPPharoTools removeClass: parent.
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'subclass') ]
	ensure: [
		(Smalltalk globals includesKey: child asSymbol) ifTrue: [ (Smalltalk globals at: child asSymbol) removeFromSystem ].
		(Smalltalk globals includesKey: parent asSymbol) ifTrue: [ (Smalltalk globals at: parent asSymbol) removeFromSystem ] ]
]

{ #category : 'tests - runCritics' }
MCPPharoToolsRunningTest >> testRunCriticsOnClassUnknown [
	| r |
	r := MCPPharoTools runCriticsOnClass: 'NoSuchClassXYZ'.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - runCritics' }
MCPPharoToolsRunningTest >> testRunCriticsOnClassValid [
	| r |
	r := MCPPharoTools runCriticsOnClass: 'MCPServer'.
	self deny: (r beginsWith: 'Error')
]

{ #category : 'tests - runCritics' }
MCPPharoToolsRunningTest >> testRunCriticsOnPackageUnknown [
	| r |
	r := MCPPharoTools runCriticsOnPackage: 'NoSuchPkgXYZ'.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchPkgXYZ')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassAllTests [
	| r |
	r := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil.
	self assert: (r includesSubstring: 'passed').
	self assert: (r includesSubstring: 'MCPToolTest')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassIncludesDuration [
	| r |
	r := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil.
	self assert: (r includesSubstring: 'ms')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassNonTestCase [
	| r |
	r := MCPPharoTools runTestsForClass: 'OrderedCollection' selector: nil.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'OrderedCollection')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassSingleSelector [
	| r |
	r := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: 'testToolCreation'.
	self assert: (r includesSubstring: 'MCPToolTest').
	self assert: (r includesSubstring: 'testToolCreation').
	self assert: (r includesSubstring: '1 passed')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassUnknownClass [
	| r |
	r := MCPPharoTools runTestsForClass: 'NoSuchClassXYZ' selector: nil.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageIncludesDuration [
	| r |
	r := MCPPharoTools runTestsInPackage: 'SUnit-MockObjects-Tests'.
	self assert: (r includesSubstring: 'ms')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageNoTestCases [
	| r |
	r := MCPPharoTools runTestsInPackage: 'PharoMCP'.
	self assert: (r beginsWith: 'Error')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageSuccess [
	| r |
	r := MCPPharoTools runTestsInPackage: 'SUnit-MockObjects-Tests'.
	self assert: (r includesSubstring: 'passed')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageUnknown [
	| r |
	r := MCPPharoTools runTestsInPackage: 'NoSuchPkgXYZ'.
	self assert: (r beginsWith: 'Error').
	self assert: (r includesSubstring: 'NoSuchPkgXYZ')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceCaseSensitiveMiss [
	| r |
	r := MCPPharoTools searchSourceFor: 'PASSEDCOUNT' inClass: 'MCPPharoTools' caseSensitive: true.
	self assert: (r includesSubstring: 'No methods found')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceInClassFindsMatch [
	| r |
	r := MCPPharoTools searchSourceFor: 'passedCount' inClass: 'MCPPharoTools' caseSensitive: false.
	self assert: (r includesSubstring: 'formatResult')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceInClassNoMatch [
	| r |
	r := MCPPharoTools searchSourceFor: 'xyzNoSuchPatternABC' inClass: 'MCPPharoTools' caseSensitive: false.
	self assert: (r includesSubstring: 'No methods found')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceInClassUnknown [
	| r |
	r := MCPPharoTools searchSourceFor: 'foo' inClass: 'NoSuchClassXYZ' caseSensitive: false.
	self assert: (r beginsWith: 'Error')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceInPackageFindsMatch [
	| r |
	r := MCPPharoTools searchSourceFor: 'processRawRequest' inPackage: 'PharoMCP' caseSensitive: false.
	self deny: (r beginsWith: 'Error').
	self assert: (r includesSubstring: '>>')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceInPackageUnknown [
	| r |
	r := MCPPharoTools searchSourceFor: 'foo' inPackage: 'NoSuchPkgXYZ' caseSensitive: false.
	self assert: (r beginsWith: 'Error')
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceToolHasCorrectName [
	self assert: MCPPharoTools searchSourceTool name equals: 'search_source'
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [:t | t name = 'search_source'])
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testSetClassCommentRoundtrip [
	| original r |
	original := MCPPharoToolsRunningTest comment.
	[ r := MCPPharoTools setClassComment: 'Test comment XYZ' onClass: 'MCPPharoToolsRunningTest'.
	self assert: (r beginsWith: 'Comment set on:').
	self assert: (MCPPharoTools getClassComment: 'MCPPharoToolsRunningTest') equals: 'Test comment XYZ' ]
	ensure: [ MCPPharoToolsRunningTest comment: original ]
]
