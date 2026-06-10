Class {
	#name : 'MCPPharoToolsRunningTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

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
	self assert: r size > 0
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
	r := MCPPharoTools formatResult: result forName: 'MyClass' selector: nil.
	self assert: (r includesSubstring: 'Ran').
	self assert: (r includesSubstring: 'MyClass').
	self assert: (r includesSubstring: 'passed')
]

{ #category : 'tests - formatResult' }
MCPPharoToolsRunningTest >> testFormatResultWithSelector [
	| result r |
	result := MCPTestResult new.
	r := MCPPharoTools formatResult: result forName: 'MyClass' selector: 'myTest'.
	self assert: (r includesSubstring: 'MyClass').
	self assert: (r includesSubstring: 'myTest')
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
