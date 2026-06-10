Class {
	#name : 'MCPPharoToolsExtendedTest',
	#superclass : 'TestCase',
	#instVars : [
		'processor'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'helpers' }
MCPPharoToolsExtendedTest >> call: toolName args: argDict [
	^ (processor tools at: toolName) call: argDict
]

{ #category : 'running' }
MCPPharoToolsExtendedTest >> setUp [
	super setUp.
	processor := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: processor
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyOnMissingClassName [
	self assert: ((self call: 'class_hierarchy' args: Dictionary new) beginsWith: 'Error')
]

{ #category : 'tests - class_hierarchy' }
MCPPharoToolsExtendedTest >> testClassHierarchyOnUnknownClass [
	| r | r := self call: 'class_hierarchy' args: (Dictionary new at: 'class_name' put: 'NoSuchXYZ'; yourself).
	self assert: (r beginsWith: 'Error'). self assert: (r includesSubstring: 'NoSuchXYZ')
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

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsOnMissingSelector [
	self assert: ((self call: 'find_implementors' args: Dictionary new) beginsWith: 'Error')
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsOnUnknownSelector [
	| r | r := self call: 'find_implementors' args: (Dictionary new at: 'selector' put: 'noSuchXYZABC'; yourself).
	self assert: (r includesSubstring: 'No implementors')
]

{ #category : 'tests - find_implementors' }
MCPPharoToolsExtendedTest >> testFindImplementorsReturnsResults [
	| r | r := self call: 'find_implementors' args: (Dictionary new at: 'selector' put: 'printOn:'; yourself).
	self deny: (r beginsWith: 'Error'). self assert: r size > 0
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
	self assert: ((self call: 'find_senders' args: Dictionary new) beginsWith: 'Error')
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
	self assert: ((self call: 'run_critics' args: Dictionary new) beginsWith: 'Error')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnUnknownClass [
	| r | r := self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'NoSuchXYZ'; yourself).
	self assert: (r beginsWith: 'Error'). self assert: (r includesSubstring: 'NoSuchXYZ')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnUnknownPackage [
	| r | r := self call: 'run_critics' args: (Dictionary new at: 'package' put: 'NoSuchPkgXYZ'; yourself).
	self assert: (r beginsWith: 'Error'). self assert: (r includesSubstring: 'NoSuchPkgXYZ')
]

{ #category : 'tests - run_critics' }
MCPPharoToolsExtendedTest >> testRunCriticsOnValidClass [
	| r | r := self call: 'run_critics' args: (Dictionary new at: 'class_name' put: 'MCPServer'; yourself).
	self deny: (r beginsWith: 'Error')
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
