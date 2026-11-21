Class {
	#name : 'MCPPharoToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'running' }
MCPPharoToolsTest >> setUp [
	super setUp.
	tool := MCPPharoTools runTestsTool
]

{ #category : 'tests - annotations' }
MCPPharoToolsTest >> testDestructiveToolsAreAnnotatedDestructive [

	#( 'class_remove' 'package_remove' 'delete_method' 'evaluate_pharo' ) do: [ :each |
		| tool |
		tool := self toolNamed: each.
		self assert: (tool annotations at: 'destructiveHint') description: each , ' should be destructive'.
		self deny: (tool annotations at: 'readOnlyHint') description: each , ' should not be read only' ]
]

{ #category : 'tests - annotations' }
MCPPharoToolsTest >> testEveryToolIsAnnotated [

	"Left unset, the specification's defaults apply, and they say destructive and open world.
	 No tool of this server is either, so none may be left to them."

	MCPPharoTools allTools do: [ :each |
		self deny: each title isNil description: each name , ' has no title'.
		self deny: each annotations isNil description: each name , ' has no annotations'.
		self deny: (each annotations at: 'openWorldHint') description: each name , ' is not an open world tool' ]
]

{ #category : 'tests' }
MCPPharoToolsTest >> testListMethodsOnUnknownClassSaysSo [

	| tool |
	tool := MCPPharoTools listMethodsTool.
	self
		assert: (tool call: (Dictionary new at: 'className' put: 'NoSuchClassHere'; yourself))
		equals: 'Error: class not found: NoSuchClassHere'
]

{ #category : 'tests - MCPTestResult' }
MCPPharoToolsTest >> testMCPTestResultPassCount [
	| result |
	result := MCPTestResult new.
	MCPToolTest suite run: result.
	self assert: result passedCount equals: MCPToolTest suite tests size.
	self assert: result failureMessages isEmpty.
	self assert: result errorMessages isEmpty
]

{ #category : 'tests - annotations' }
MCPPharoToolsTest >> testReadOnlyToolsAreAnnotatedReadOnly [

	#( 'class_definition' 'class_hierarchy' 'list_classes' 'list_methods' 'list_packages'
		'method_source' 'find_implementors' 'find_senders' 'search_source' 'run_critics' )
		do: [ :each |
			| tool |
			tool := self toolNamed: each.
			self assert: (tool annotations at: 'readOnlyHint') description: each , ' should be read only'.
			self deny: (tool annotations at: 'destructiveHint') description: each , ' should not be destructive' ]
]

{ #category : 'tests' }
MCPPharoToolsTest >> testRunTestsAllInClass [

	| report |
	report := tool call: (Dictionary new at: 'class_name' put: 'MCPToolTest'; yourself).
	self assert: (report at: 'target') equals: 'MCPToolTest'.
	self assert: (report at: 'passedCount') equals: (report at: 'runCount')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnMissingArgs [
	self assert: ((tool call: Dictionary new) beginsWith: 'Error')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnNonTestClass [
	| result |
	result := tool call: (Dictionary new at: 'class_name' put: 'OrderedCollection'; yourself).
	self assert: (result includesSubstring: 'Error').
	self assert: (result includesSubstring: 'TestCase')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnUnknownClass [
	| result |
	result := tool call: (Dictionary new at: 'class_name' put: 'NoSuchClassXYZ'; yourself).
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchClassXYZ')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnUnknownPackage [
	| result |
	result := tool call: (Dictionary new at: 'package' put: 'NoSuchPackageXYZ'; yourself).
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchPackageXYZ')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsPackageNotFound [
	| result |
	result := tool call: (Dictionary new at: 'package' put: 'NoSuchPackageXYZ'; yourself).
	self assert: (result beginsWith: 'Error').
	self assert: (result includesSubstring: 'NoSuchPackageXYZ')
]

{ #category : 'tests' }
MCPPharoToolsTest >> testRunTestsPackageSuccess [

	"Uses a small non-PharoMCP package to avoid recursive suite building"

	| report |
	report := tool call: (Dictionary new at: 'package' put: 'Transcript-NonInteractive-Tests'; yourself).
	self assert: (report at: 'target') equals: 'Transcript-NonInteractive-Tests'.
	self assert: (report at: 'passedCount') equals: (report at: 'runCount')
]

{ #category : 'tests' }
MCPPharoToolsTest >> testRunTestsSingleSelector [

	| report |
	report := tool call: (Dictionary new at: 'class_name' put: 'MCPToolTest'; at: 'selector' put: 'testToolCreation'; yourself).
	self assert: (report at: 'target') equals: 'MCPToolTest'.
	self assert: (report at: 'selector') equals: 'testToolCreation'.
	self assert: (report at: 'passedCount') equals: 1
]

{ #category : 'tests - schema' }
MCPPharoToolsTest >> testToolHasCorrectName [
	self assert: tool name equals: 'run_tests'
]

{ #category : 'tests - schema' }
MCPPharoToolsTest >> testToolSchemaHasAllParams [
	| props |
	props := tool inputSchema at: 'properties'.
	self assert: (props includesKey: 'class_name').
	self assert: (props includesKey: 'selector').
	self assert: (props includesKey: 'package')
]

{ #category : 'helpers' }
MCPPharoToolsTest >> toolNamed: aString [

	^ MCPPharoTools allTools detect: [ :each | each name = aString ]
]
