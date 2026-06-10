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

{ #category : 'tests - MCPTestResult' }
MCPPharoToolsTest >> testMCPTestResultPassCount [
	| result |
	result := MCPTestResult new.
	MCPToolTest suite run: result.
	self assert: result passedCount equals: MCPToolTest suite tests size.
	self assert: result failureMessages isEmpty.
	self assert: result errorMessages isEmpty
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsAllInClass [
	| result |
	result := tool call: (Dictionary new at: 'class_name' put: 'MCPToolTest'; yourself).
	self assert: (result includesSubstring: 'passed').
	self assert: (result includesSubstring: 'MCPToolTest')
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

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsPackageSuccess [
	"Uses a small non-PharoMCP package to avoid recursive suite building"
	| result |
	result := tool call: (Dictionary new at: 'package' put: 'Transcript-NonInteractive-Tests'; yourself).
	self assert: (result includesSubstring: 'Transcript-NonInteractive-Tests').
	self assert: (result includesSubstring: 'passed')
]

{ #category : 'tests - run_tests' }
MCPPharoToolsTest >> testRunTestsSingleSelector [
	| result |
	result := tool call: (Dictionary new at: 'class_name' put: 'MCPToolTest'; at: 'selector' put: 'testToolCreation'; yourself).
	self assert: (result includesSubstring: 'MCPToolTest').
	self assert: (result includesSubstring: 'testToolCreation').
	self assert: (result includesSubstring: '1 passed')
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
