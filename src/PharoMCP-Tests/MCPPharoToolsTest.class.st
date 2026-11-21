"
Holds the tool factories to their names, their schemas and their annotations.
"
Class {
	#name : 'MCPPharoToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool'
	],
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
MCPPharoToolsTest >> setUp [
	super setUp.
	tool := MCPPharoTools runTestsTool
]

{ #category : 'tests - annotations' }
MCPPharoToolsTest >> testDestructiveToolsAreAnnotatedDestructive [

	#( 'class_remove' 'package_remove' 'delete_method' 'evaluate_pharo' ) do: [ :each |
		| annotations |
		annotations := (self toolNamed: each) annotations.
		self assert: (annotations at: 'destructiveHint') description: each , ' should be destructive'.
		self deny: (annotations at: 'readOnlyHint') description: each , ' should not be read only' ]
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
MCPPharoToolsTest >> testEveryToolIsItsOwnClass [

	"One class per tool: its name, description, schema and body are methods of a class, not
	 literals inside a factory. A tool left as an MCPTool built from a block still carries the
	 block in its handler."
	MCPPharoTools allTools do: [ :tool |
		self
			deny: tool class = MCPTool
			description: tool name , ' is still built from a block'.
		self
			assert: tool handler isNil
			description: tool name , ' still carries a handler block' ]
]

{ #category : 'tests' }
MCPPharoToolsTest >> testListMethodsOnUnknownClassSaysSo [

	| listMethods |
	listMethods := MCPPharoTools listMethodsTool.
	self
		should: [ listMethods call: (Dictionary new at: 'className' put: 'NoSuchClassHere'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: e messageText equals: 'class not found: NoSuchClassHere' ]
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
			| annotations |
			annotations := (self toolNamed: each) annotations.
			self assert: (annotations at: 'readOnlyHint') description: each , ' should be read only'.
			self deny: (annotations at: 'destructiveHint') description: each , ' should not be destructive' ]
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

	self
		should: [ tool call: Dictionary new ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'provide class_name or package') ]
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnNonTestClass [

	self
		should: [ tool call: (Dictionary new at: 'class_name' put: 'OrderedCollection'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'TestCase') ]
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnUnknownClass [

	self
		should: [ tool call: (Dictionary new at: 'class_name' put: 'NoSuchClassXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsErrorOnUnknownPackage [

	self
		should: [ tool call: (Dictionary new at: 'package' put: 'NoSuchPackageXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPackageXYZ') ]
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsPackageNotFound [

	self
		should: [ tool call: (Dictionary new at: 'package' put: 'NoSuchPackageXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPackageXYZ') ]
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
