"
Holds the tools that change or run code to their effect on the image: compiling, renaming, moving, removing, running tests and running the critics.
"
Class {
	#name : 'MCPPharoToolsRunningTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
MCPPharoToolsRunningTest >> assertReport: aReport satisfies: aSchema [

	(aSchema at: 'required') do: [ :key |
		self assert: (aReport includesKey: key) description: key , ' is required but absent' ].
	aReport keysAndValuesDo: [ :key :value |
		| declared |
		declared := (aSchema at: 'properties') at: key ifAbsent: [ nil ].
		self deny: declared isNil description: key , ' is emitted but not declared'.
		(declared at: 'type') = 'integer' ifTrue: [
			self assert: value isInteger description: key , ' is declared an integer' ].
		(declared at: 'type') = 'string' ifTrue: [
			self assert: value isString description: key , ' is declared a string' ].
		(declared at: 'type') = 'array' ifTrue: [
			self assert: value isCollection description: key , ' is declared an array' ] ]
]

{ #category : 'private' }
MCPPharoToolsRunningTest >> tempNewName [ ^ 77
]

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

	self
		should: [ MCPPharoTools classHierarchyOf: 'NoSuchClassXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
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

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testCompileMethodClassSide [

	| result |
	result := MCPPharoTools compileMethod: 'compileTestClassMethod ^ 77'
		onClass: self class name
		side: 'class'
		classified: 'private'.
	self assert: (result includesSubstring: 'class').
	self assert: self class compileTestClassMethod equals: 77.
	self class classSide removeSelector: #compileTestClassMethod
]

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testCompileMethodNormalisesLF [

	"The line feed is built from Character lf rather than written into the literal, because
	 the tool under test normalises line endings and would otherwise be handed a CR."

	| lfSource result |
	lfSource := 'lfTestMethod' , Character lf asString , '	^ 55'.
	result := MCPPharoTools compileMethod: lfSource
		onClass: self class name
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Compiled:').
	self assert: self class new lfTestMethod equals: 55.
	self class removeSelector: #lfTestMethod
]

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testCompileMethodSuccess [

	| result |
	result := MCPPharoTools compileMethod: 'compileTestMethod ^ 99'
		onClass: self class name
		side: 'instance'
		classified: 'private'.
	self assert: (result beginsWith: 'Compiled:').
	self assert: (result includesSubstring: 'compileTestMethod').
	self assert: self class new compileTestMethod equals: 99.
	self class removeSelector: #compileTestMethod
]

{ #category : 'tests - compileMethod' }
MCPPharoToolsRunningTest >> testCompileMethodSyntaxError [

	self
		should: [ MCPPharoTools
			compileMethod: 'this is not valid smalltalk !!!'
			onClass: 'MCPPharoToolsRunningTest'
			side: 'instance'
			classified: 'private' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'compilation failed') ]
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

	self
		should: [ MCPPharoTools
			compileMethod: 'foo ^ 1'
			onClass: 'NoSuchClassXYZ'
			side: 'instance'
			classified: 'private' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - createClass' }
MCPPharoToolsRunningTest >> testCreateClassAlreadyExists [

	self
		should: [ MCPPharoTools
			createClass: 'Object'
			superclass: 'Object'
			instanceVariables: #()
			package: 'PharoMCP-Tests' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'already exists') ]
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

	self
		should: [ MCPPharoTools
			createClass: 'MCPTestTempClassBBB'
			superclass: 'NoSuchSuperclassXYZ'
			instanceVariables: #()
			package: 'PharoMCP-Tests' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchSuperclassXYZ') ]
]

{ #category : 'tests - createPackage' }
MCPPharoToolsRunningTest >> testCreatePackageAlreadyExists [

	self
		should: [ MCPPharoTools createPackage: 'PharoMCP' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'already exists') ]
]

{ #category : 'tests - createPackage' }
MCPPharoToolsRunningTest >> testCreatePackageSuccess [
	| result |
	[ result := MCPPharoTools createPackage: 'MCPTestTempPkgAAA'.
	self assert: (result beginsWith: 'Created package:').
	self assert: (Smalltalk packageOrganizer hasPackage: 'MCPTestTempPkgAAA') ]
	ensure: [
		(Smalltalk packageOrganizer hasPackage: 'MCPTestTempPkgAAA') ifTrue: [
			Smalltalk packageOrganizer removePackage:
				(Smalltalk packageOrganizer packageNamed: 'MCPTestTempPkgAAA') ] ]
]

{ #category : 'tests - createPackage' }
MCPPharoToolsRunningTest >> testCreatePackageToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'package_create' ])
]

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testDeleteMethodClassSide [

	| result |
	self class classSide compile: 'tempDeleteMeClass ^ 0' classified: 'private'.
	result := MCPPharoTools deleteMethod: 'tempDeleteMeClass' fromClass: self class name side: 'class'.
	self assert: (result includesSubstring: 'class').
	self deny: (self class classSide includesSelector: #tempDeleteMeClass)
]

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testDeleteMethodSuccess [

	| result |
	self class compile: 'tempDeleteMe ^ 0' classified: 'private'.
	result := MCPPharoTools deleteMethod: 'tempDeleteMe' fromClass: self class name side: 'instance'.
	self assert: (result beginsWith: 'Deleted:').
	self deny: (self class includesSelector: #tempDeleteMe)
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

	self
		should: [ MCPPharoTools deleteMethod: 'foo' fromClass: 'NoSuchClassXYZ' side: 'instance' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - deleteMethod' }
MCPPharoToolsRunningTest >> testDeleteMethodUnknownSelector [

	self
		should: [ MCPPharoTools deleteMethod: 'noSuchSelectorXYZ' fromClass: 'MCPPharoToolsRunningTest' side: 'instance' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'noSuchSelectorXYZ') ]
]

{ #category : 'tests - findImplementors' }
MCPPharoToolsRunningTest >> testFindImplementorsOfEmptySelector [

	self
		should: [ MCPPharoTools findImplementorsOf: '' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'selector is required') ]
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

	self
		should: [ MCPPharoTools findSendersOf: '' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'selector is required') ]
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

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testGetClassCommentNoComment [

	| className |
	className := 'MCPCommentlessSubject'.
	(Object << className asSymbol package: 'PharoMCP-Tests') install.
	[ self assert: (MCPPharoTools getClassComment: className) equals: '(no comment)' ]
		ensure: [ (Smalltalk globals at: className asSymbol) removeFromSystem ]
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testGetClassCommentReturnsComment [
	| r |
	r := MCPPharoTools getClassComment: 'MCPServer'.
	self deny: (r beginsWith: 'Error')
]

{ #category : 'tests - classComment' }
MCPPharoToolsRunningTest >> testGetClassCommentUnknownClass [

	self
		should: [ MCPPharoTools getClassComment: 'NoSuchClassXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
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

{ #category : 'tests - moveMethod' }
MCPPharoToolsRunningTest >> testMoveMethodConflict [

	| srcCls tgtCls |
	MCPPharoTools createClass: 'MCPTestMoveConflictSrc' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	MCPPharoTools createClass: 'MCPTestMoveConflictTgt' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	srcCls := Smalltalk globals at: #MCPTestMoveConflictSrc.
	tgtCls := Smalltalk globals at: #MCPTestMoveConflictTgt.
	[ srcCls compile: 'sharedSel ^ 1' classified: 'private'.
	tgtCls compile: 'sharedSel ^ 2' classified: 'private'.
	self
		should: [ MCPPharoTools moveMethod: 'sharedSel' fromClass: 'MCPTestMoveConflictSrc' side: 'instance' toClass: 'MCPTestMoveConflictTgt' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'already defined') ] ]
	ensure: [
		(Smalltalk globals includesKey: #MCPTestMoveConflictSrc) ifTrue: [ (Smalltalk globals at: #MCPTestMoveConflictSrc) removeFromSystem ].
		(Smalltalk globals includesKey: #MCPTestMoveConflictTgt) ifTrue: [ (Smalltalk globals at: #MCPTestMoveConflictTgt) removeFromSystem ] ]
]

{ #category : 'tests - moveMethod' }
MCPPharoToolsRunningTest >> testMoveMethodSuccess [
	| srcCls tgtCls result |
	MCPPharoTools createClass: 'MCPTestMoveSrcIII' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	MCPPharoTools createClass: 'MCPTestMoveTgtIII' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	srcCls := Smalltalk globals at: #MCPTestMoveSrcIII.
	tgtCls := Smalltalk globals at: #MCPTestMoveTgtIII.
	[ srcCls compile: 'movedMethod ^ 55' classified: 'private'.
	result := MCPPharoTools moveMethod: 'movedMethod' fromClass: 'MCPTestMoveSrcIII' side: 'instance' toClass: 'MCPTestMoveTgtIII'.
	self assert: (result includesSubstring: 'movedMethod').
	self deny: (srcCls includesSelector: #movedMethod).
	self assert: (tgtCls includesSelector: #movedMethod).
	self assert: tgtCls new movedMethod equals: 55 ]
	ensure: [
		(Smalltalk globals includesKey: #MCPTestMoveSrcIII) ifTrue: [ (Smalltalk globals at: #MCPTestMoveSrcIII) removeFromSystem ].
		(Smalltalk globals includesKey: #MCPTestMoveTgtIII) ifTrue: [ (Smalltalk globals at: #MCPTestMoveTgtIII) removeFromSystem ] ]
]

{ #category : 'tests - moveMethod' }
MCPPharoToolsRunningTest >> testMoveMethodToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'method_move' ])
]

{ #category : 'tests - moveMethod' }
MCPPharoToolsRunningTest >> testMoveMethodUnknownSource [

	self
		should: [ MCPPharoTools moveMethod: 'foo' fromClass: 'NoSuchClassXYZ' side: 'instance' toClass: 'MCPTool' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
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

	self
		should: [ MCPPharoTools removeClass: 'NoSuchClassXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - removeClass' }
MCPPharoToolsRunningTest >> testRemoveClassWithSubclassesFails [

	| parent child |
	parent := 'MCPTestTempParentEEE'.
	child := 'MCPTestTempChildEEE'.
	[ MCPPharoTools createClass: parent superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	MCPPharoTools createClass: child superclass: parent instanceVariables: #() package: 'PharoMCP-Tests'.
	self
		should: [ MCPPharoTools removeClass: parent ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'subclass') ] ]
	ensure: [
		(Smalltalk globals includesKey: child asSymbol) ifTrue: [ (Smalltalk globals at: child asSymbol) removeFromSystem ].
		(Smalltalk globals includesKey: parent asSymbol) ifTrue: [ (Smalltalk globals at: parent asSymbol) removeFromSystem ] ]
]

{ #category : 'tests - removePackage' }
MCPPharoToolsRunningTest >> testRemovePackageNotEmpty [

	self
		should: [ MCPPharoTools removePackage: 'PharoMCP' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'not empty') ]
]

{ #category : 'tests - removePackage' }
MCPPharoToolsRunningTest >> testRemovePackageSuccess [
	| result |
	MCPPharoTools createPackage: 'MCPTestTempPkgBBB'.
	result := MCPPharoTools removePackage: 'MCPTestTempPkgBBB'.
	self assert: (result beginsWith: 'Removed package:').
	self deny: (Smalltalk packageOrganizer hasPackage: 'MCPTestTempPkgBBB')
]

{ #category : 'tests - removePackage' }
MCPPharoToolsRunningTest >> testRemovePackageToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'package_remove' ])
]

{ #category : 'tests - removePackage' }
MCPPharoToolsRunningTest >> testRemovePackageUnknown [

	self
		should: [ MCPPharoTools removePackage: 'NoSuchPkgXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPkgXYZ') ]
]

{ #category : 'tests - renameClass' }
MCPPharoToolsRunningTest >> testRenameClassConflict [

	self
		should: [ MCPPharoTools renameClass: 'MCPServer' to: 'MCPTool' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'already exists') ]
]

{ #category : 'tests - renameClass' }
MCPPharoToolsRunningTest >> testRenameClassSuccess [
	| result |
	MCPPharoTools createClass: 'MCPTestOldNameHHH' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	[ result := MCPPharoTools renameClass: 'MCPTestOldNameHHH' to: 'MCPTestNewNameHHH'.
	self assert: (result includesSubstring: 'MCPTestOldNameHHH').
	self assert: (result includesSubstring: 'MCPTestNewNameHHH').
	self deny: (Smalltalk globals includesKey: #MCPTestOldNameHHH).
	self assert: (Smalltalk globals includesKey: #MCPTestNewNameHHH) ]
	ensure: [
		(Smalltalk globals includesKey: #MCPTestOldNameHHH) ifTrue: [ (Smalltalk globals at: #MCPTestOldNameHHH) removeFromSystem ].
		(Smalltalk globals includesKey: #MCPTestNewNameHHH) ifTrue: [ (Smalltalk globals at: #MCPTestNewNameHHH) removeFromSystem ] ]
]

{ #category : 'tests - renameClass' }
MCPPharoToolsRunningTest >> testRenameClassToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'class_rename' ])
]

{ #category : 'tests - renameClass' }
MCPPharoToolsRunningTest >> testRenameClassUnknown [

	self
		should: [ MCPPharoTools renameClass: 'NoSuchClassXYZ' to: 'AnyName' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - renameMethod' }
MCPPharoToolsRunningTest >> testRenameMethodSuccess [
	| cls result |
	MCPPharoTools createClass: 'MCPTestRenameSubjectFFF' superclass: 'Object' instanceVariables: #() package: 'PharoMCP-Tests'.
	cls := Smalltalk globals at: #MCPTestRenameSubjectFFF.
	[ cls compile: 'oldSel ^ 99' classified: 'private'.
	result := MCPPharoTools renameMethod: 'oldSel' onClass: 'MCPTestRenameSubjectFFF' side: 'instance' to: 'newSel'.
	self assert: (result includesSubstring: 'oldSel').
	self assert: (result includesSubstring: 'newSel').
	self deny: (cls includesSelector: #oldSel).
	self assert: (cls includesSelector: #newSel).
	self assert: cls new newSel equals: 99 ]
	ensure: [ (Smalltalk globals includesKey: #MCPTestRenameSubjectFFF) ifTrue: [
		(Smalltalk globals at: #MCPTestRenameSubjectFFF) removeFromSystem ] ]
]

{ #category : 'tests - renameMethod' }
MCPPharoToolsRunningTest >> testRenameMethodToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [ :t | t name = 'method_rename' ])
]

{ #category : 'tests - renameMethod' }
MCPPharoToolsRunningTest >> testRenameMethodUnknownClass [

	self
		should: [ MCPPharoTools renameMethod: 'foo' onClass: 'NoSuchClassXYZ' side: 'instance' to: 'bar' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - renameMethod' }
MCPPharoToolsRunningTest >> testRenameMethodUnknownSelector [

	self
		should: [ MCPPharoTools renameMethod: 'noSuchSelectorXYZ' onClass: 'MCPPharoToolsRunningTest' side: 'instance' to: 'bar' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'noSuchSelectorXYZ') ]
]

{ #category : 'tests - structured results' }
MCPPharoToolsRunningTest >> testReportsSatisfyTheirOutputSchemas [

	self
		assertReport: (MCPPharoTools runTestsForClass: 'MCPToolTest' selector: 'testToolCreation')
		satisfies: MCPPharoTools runTestsTool outputSchema.
	self
		assertReport: (MCPPharoTools runTestsInPackage: 'SUnit-MockObjects-Tests')
		satisfies: MCPPharoTools runTestsTool outputSchema.
	self
		assertReport: (MCPPharoTools runCriticsOnClass: 'MCPPharoTools')
		satisfies: MCPPharoTools runCriticsTool outputSchema
]

{ #category : 'tests - structured results' }
MCPPharoToolsRunningTest >> testRunCriticsAnswersStructuredContent [

	| report |
	report := MCPPharoTools runCriticsOnClass: 'MCPTool'.
	self assert: (report at: 'target') equals: 'MCPTool'.
	self assert: (report at: 'critiqueCount') equals: (report at: 'critiques') size.
	self assert: ((report at: 'summary') isString)
]

{ #category : 'tests - runCritics' }
MCPPharoToolsRunningTest >> testRunCriticsOnClassUnknown [

	self
		should: [ MCPPharoTools runCriticsOnClass: 'NoSuchClassXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunCriticsOnClassValid [

	| report |
	report := MCPPharoTools runCriticsOnClass: 'MCPServer'.
	self assert: (report at: 'target') equals: 'MCPServer'.
	self assert: (report at: 'critiques') size equals: (report at: 'critiqueCount')
]

{ #category : 'tests - runCritics' }
MCPPharoToolsRunningTest >> testRunCriticsOnPackageUnknown [

	self
		should: [ MCPPharoTools runCriticsOnPackage: 'NoSuchPkgXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPkgXYZ') ]
]

{ #category : 'tests - structured results' }
MCPPharoToolsRunningTest >> testRunTestsAnswersStructuredContent [

	| report |
	report := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil.
	self assert: (report at: 'target') equals: 'MCPToolTest'.
	self assert: (report at: 'runCount') equals: MCPToolTest buildSuite tests size.
	self assert: (report at: 'passedCount') equals: (report at: 'runCount').
	self assert: (report at: 'failedCount') equals: 0.
	self assert: (report at: 'erroredCount') equals: 0.
	self assert: (report at: 'durationMilliseconds') isNumber.
	self assert: (report at: 'failures') isEmpty.
	self assert: ((report at: 'summary') includesSubstring: 'passed')
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunTestsForClassAllTests [

	| report |
	report := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil.
	self assert: (report at: 'target') equals: 'MCPToolTest'.
	self assert: (report at: 'passedCount') equals: (report at: 'runCount')
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunTestsForClassIncludesDuration [

	| report |
	report := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: nil.
	self assert: (report at: 'durationMilliseconds') isInteger.
	self assert: ((report at: 'summary') includesSubstring: 'ms')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassNonTestCase [

	self
		should: [ MCPPharoTools runTestsForClass: 'OrderedCollection' selector: nil ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'OrderedCollection') ]
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunTestsForClassSingleSelector [

	| report |
	report := MCPPharoTools runTestsForClass: 'MCPToolTest' selector: 'testToolCreation'.
	self assert: (report at: 'target') equals: 'MCPToolTest'.
	self assert: (report at: 'selector') equals: 'testToolCreation'.
	self assert: (report at: 'runCount') equals: 1.
	self assert: (report at: 'passedCount') equals: 1
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsForClassUnknownClass [

	self
		should: [ MCPPharoTools runTestsForClass: 'NoSuchClassXYZ' selector: nil ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunTestsInPackageIncludesDuration [

	| report |
	report := MCPPharoTools runTestsInPackage: 'SUnit-MockObjects-Tests'.
	self assert: (report at: 'durationMilliseconds') isInteger.
	self assert: ((report at: 'summary') includesSubstring: 'ms')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageNoTestCases [

	self
		should: [ MCPPharoTools runTestsInPackage: 'PharoMCP' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'no TestCase subclasses') ]
]

{ #category : 'tests - running' }
MCPPharoToolsRunningTest >> testRunTestsInPackageSuccess [

	| report |
	report := MCPPharoTools runTestsInPackage: 'SUnit-MockObjects-Tests'.
	self assert: (report at: 'target') equals: 'SUnit-MockObjects-Tests'.
	self assert: (report at: 'passedCount') equals: (report at: 'runCount')
]

{ #category : 'tests - runTests' }
MCPPharoToolsRunningTest >> testRunTestsInPackageUnknown [

	self
		should: [ MCPPharoTools runTestsInPackage: 'NoSuchPkgXYZ' ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPkgXYZ') ]
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

	self
		should: [ MCPPharoTools searchSourceFor: 'foo' inClass: 'NoSuchClassXYZ' caseSensitive: false ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
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

	self
		should: [ MCPPharoTools searchSourceFor: 'foo' inPackage: 'NoSuchPkgXYZ' caseSensitive: false ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPkgXYZ') ]
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceToolHasCorrectName [
	self assert: MCPPharoTools searchSourceTool name equals: 'search_source'
]

{ #category : 'tests - searchSource' }
MCPPharoToolsRunningTest >> testSearchSourceToolInAllTools [
	self assert: (MCPPharoTools allTools anySatisfy: [:t | t name = 'search_source'])
]

{ #category : 'tests' }
MCPPharoToolsRunningTest >> testSetClassCommentRoundtrip [

	| original result |
	original := self class comment.
	[ result := MCPPharoTools setClassComment: 'Test comment XYZ' onClass: self class name.
	self assert: (result beginsWith: 'Comment set on:').
	self assert: (MCPPharoTools getClassComment: self class name) equals: 'Test comment XYZ' ]
		ensure: [ self class comment: original ]
]
