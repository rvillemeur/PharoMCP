"
Holds each tool to what it answers when called through a processor, the error cases included.
"
Class {
	#name : 'MCPPharoToolsExtendedTest',
	#superclass : 'TestCase',
	#instVars : [
		'processor'
	],
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
MCPPharoToolsExtendedTest >> call: toolName args: argDict [
	^ (processor tools at: toolName) call: argDict
]

{ #category : 'running' }
MCPPharoToolsExtendedTest >> missingArgumentTextOf: toolName args: argDict [

	"The guard a required argument meets lives in the processor, not in the tool's handler, so a
	 test of it has to go through tools/call."
	| response result |
	response := processor processRawRequest: (NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'method' put: 'tools/call';
		at: 'params' put: (Dictionary new
			at: 'name' put: toolName;
			at: 'arguments' put: argDict;
			yourself);
		yourself)).
	result := (NeoJSONReader fromString: response) at: 'result'.
	self assert: (result at: 'isError') description: toolName , ' answered isError false'.
	^ (result at: 'content') first at: 'text'
]

{ #category : 'running' }
MCPPharoToolsExtendedTest >> setUp [
	super setUp.
	processor := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: processor
]

{ #category : 'running' }
MCPPharoToolsExtendedTest >> tearDown [
	"A test that creates a class and removes it on its last line leaks that class when an
	earlier assertion fails, and the class lands in a repository package. Remove it here, where
	a failure cannot skip the removal."

	(Smalltalk globals at: #TestCreateMCPXYZ ifAbsent: [ nil ])
		ifNotNil: [ :leftover | leftover removeFromSystem ].
	super tearDown
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyOnMissingClassName [

	self
		assert: ((self missingArgumentTextOf: 'class_hierarchy' args: Dictionary new)
			includesSubstring: 'class_name')
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyOnUnknownClass [

	self
		should: [ self call: 'class_hierarchy' args: (Dictionary new at: 'class_name' put: 'NoSuchXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchXYZ') ]
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyOnValidClass [
	| r | r := self call: 'class_hierarchy' args: (Dictionary new at: 'class_name' put: 'MCPServer'; yourself).
	self assert: (r includesSubstring: 'Object'). self deny: (r beginsWith: 'Error')
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchySchemaHasClassName [
	| props |
	props := (processor tools at: 'class_hierarchy') inputSchema at: 'properties'.
	self assert: (props includesKey: 'class_name')
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyShowsSubclasses [
	| r |
	r := self call: 'class_hierarchy' args: (Dictionary new at: 'class_name' put: 'SequenceableCollection'; yourself).
	self assert: (r includesSubstring: 'OrderedCollection')
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyToolRegistered [
	self assert: (processor tools includesKey: 'class_hierarchy')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCompileMethodToolMissingArgs [

	| text |
	text := self missingArgumentTextOf: 'compile_method' args: Dictionary new.
	self assert: (text includesSubstring: 'class_name').
	self assert: (text includesSubstring: 'source')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCompileMethodToolRegistered [
	self assert: (processor tools includesKey: 'compile_method')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCompileMethodToolSuccess [

	| result |
	result := self call: 'compile_method' args: (Dictionary new
		at: 'class_name' put: self class name;
		at: 'source' put: 'extendedTestCanary ^ 123';
		at: 'protocol' put: 'private';
		yourself).
	self assert: (result beginsWith: 'Compiled:').
	self assert: self class new extendedTestCanary equals: 123.
	self class removeSelector: #extendedTestCanary
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCompileMethodToolUnknownClass [

	self
		should: [ self call: 'compile_method' args: (Dictionary new
			at: 'class_name' put: 'NoSuchClassXYZ';
			at: 'source' put: 'foo ^ 1';
			yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchClassXYZ') ]
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCreateClassToolMissingArgs [

	| text |
	text := self missingArgumentTextOf: 'class_create' args: Dictionary new.
	self assert: (text includesSubstring: 'class_name').
	self assert: (text includesSubstring: 'package')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCreateClassToolRegistered [
	self assert: (processor tools includesKey: 'class_create')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCreateClassToolSuccess [
	| r |
	r := self call: 'class_create' args: (Dictionary new
		at: 'class_name' put: 'TestCreateMCPXYZ';
		at: 'package' put: 'PharoMCP-Tests';
		yourself).
	self assert: (r beginsWith: 'Created:').
	self assert: (Smalltalk globals includesKey: #TestCreateMCPXYZ)
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testCreateClassToolUnknownSuperclass [

	self
		should: [ self call: 'class_create' args: (Dictionary new
			at: 'class_name' put: 'TestCreateMCPXYZ';
			at: 'superclass_name' put: 'NoSuchSuperXYZ';
			at: 'package' put: 'PharoMCP-Tests';
			yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchSuperXYZ') ]
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testDeleteMethodToolRegistered [
	self assert: (processor tools includesKey: 'delete_method')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testDeleteMethodToolSuccess [

	| result |
	self class compile: 'extendedDeleteCanary ^ 0' classified: 'private'.
	result := self call: 'delete_method' args: (Dictionary new
		at: 'class_name' put: self class name;
		at: 'selector' put: 'extendedDeleteCanary';
		yourself).
	self assert: (result beginsWith: 'Deleted:').
	self deny: (self class includesSelector: #extendedDeleteCanary)
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testDeleteMethodToolUnknownSelector [

	self
		should: [ self call: 'delete_method' args: (Dictionary new
			at: 'class_name' put: 'MCPPharoToolsExtendedTest';
			at: 'selector' put: 'noSuchXYZ';
			yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'noSuchXYZ') ]
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsOnMissingSelector [

	self
		assert: ((self missingArgumentTextOf: 'find_implementors' args: Dictionary new)
			includesSubstring: 'selector')
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsOnUnknownSelector [
	| r | r := self call: 'find_implementors' args: (Dictionary new at: 'selector' put: 'noSuchXYZABC'; yourself).
	self assert: (r includesSubstring: 'No implementors')
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsReturnsResults [

	| r |
	r := self call: 'find_implementors' args: (Dictionary new
			      at: 'selector' put: 'printOn:';
			      yourself).
	self deny: (r beginsWith: 'Error').
	self assert: r isNotEmpty
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsSchemaHasSelector [
	| props |
	props := (processor tools at: 'find_implementors') inputSchema at: 'properties'.
	self assert: (props includesKey: 'selector')
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsToolRegistered [
	self assert: (processor tools includesKey: 'find_implementors')
]

{ #category : 'tests - find_senders' }
MCPPharoToolsExtendedTest >> testFindSendersOnMissingSelector [

	self
		assert: ((self missingArgumentTextOf: 'find_senders' args: Dictionary new)
			includesSubstring: 'selector')
]

{ #category : 'tests - find_senders' }
MCPPharoToolsExtendedTest >> testFindSendersOnUnknownSelector [
	| r | r := self call: 'find_senders' args: (Dictionary new at: 'selector' put: 'noSuchXYZABC'; yourself).
	self assert: (r includesSubstring: 'No senders')
]

{ #category : 'tests - find_senders' }
MCPPharoToolsExtendedTest >> testFindSendersReturnsResults [
	| r | r := self call: 'find_senders' args: (Dictionary new at: 'selector' put: 'printString'; yourself).
	self deny: (r beginsWith: 'Error'). self assert: (r includesSubstring: '>>')
]

{ #category : 'tests - find_senders' }
MCPPharoToolsExtendedTest >> testFindSendersSchemaHasSelector [
	| props |
	props := (processor tools at: 'find_senders') inputSchema at: 'properties'.
	self assert: (props includesKey: 'selector')
]

{ #category : 'tests - find_senders' }
MCPPharoToolsExtendedTest >> testFindSendersToolRegistered [
	self assert: (processor tools includesKey: 'find_senders')
]

{ #category : 'tests - list_packages' }
MCPPharoToolsExtendedTest >> testListPackagesFiltersOnPattern [
	| r | r := self call: 'list_packages' args: (Dictionary new at: 'pattern' put: 'PharoMCP'; yourself).
	self assert: (r includesSubstring: 'PharoMCP'). self deny: (r includesSubstring: 'Zinc')
]

{ #category : 'tests - list_packages' }
MCPPharoToolsExtendedTest >> testListPackagesReturnsPharoMCP [
	self assert: ((self call: 'list_packages' args: Dictionary new) includesSubstring: 'PharoMCP')
]

{ #category : 'tests - list_packages' }
MCPPharoToolsExtendedTest >> testListPackagesSchemaHasPattern [
	| props |
	props := (processor tools at: 'list_packages') inputSchema at: 'properties'.
	self assert: (props includesKey: 'pattern')
]

{ #category : 'tests - list_packages' }
MCPPharoToolsExtendedTest >> testListPackagesToolRegistered [
	self assert: (processor tools includesKey: 'list_packages')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnMissingArgs [

	self
		should: [ self call: 'run_critics' args: Dictionary new ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'provide class_name or package') ]
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnUnknownClass [

	self
		should: [ self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'NoSuchXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchXYZ') ]
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnUnknownPackage [

	self
		should: [ self call: 'run_critics' args: (Dictionary new at: 'package' put: 'NoSuchPkgXYZ'; yourself) ]
		raise: MCPToolError
		withExceptionDo: [ :e |
			self assert: (e messageText includesSubstring: 'NoSuchPkgXYZ') ]
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testRunCriticsOnValidClass [

	| report |
	report := self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'MCPServer'; yourself).
	self assert: (report at: 'target') equals: 'MCPServer'.
	self assert: (report at: 'critiques') size equals: (report at: 'critiqueCount')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsPackageOverridesClassName [
	| rPkg rCls |
	rPkg := self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'MCPServer'; at: 'package' put: 'PharoMCP'; yourself).
	rCls := self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'MCPServer'; yourself).
	self deny: rPkg equals: rCls
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsSchemaHasClassNameAndPackage [
	| props |
	props := (processor tools at: 'run_critics') inputSchema at: 'properties'.
	self assert: (props includesKey: 'class_name').
	self assert: (props includesKey: 'package')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsToolRegistered [
	self assert: (processor tools includesKey: 'run_critics')
]

{ #category : 'tests' }
MCPPharoToolsExtendedTest >> testSearchSourceToolRegistered [
	self assert: (processor tools includesKey: 'search_source')
]
