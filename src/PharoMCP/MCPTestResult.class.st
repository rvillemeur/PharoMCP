"
Wraps a Pharo SUnit test result for JSON serialization by the run_tests tool. Holds status, class name, selector, and failure message.
"
Class {
	#name : 'MCPTestResult',
	#superclass : 'TestResult',
	#instVars : [
		'failureMessages',
		'errorMessages'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPTestResult >> errorMessages [
	^ errorMessages
]

{ #category : 'accessing' }
MCPTestResult >> failureMessages [
	^ failureMessages
]

{ #category : 'initialization' }
MCPTestResult >> initialize [
	super initialize.
	failureMessages := OrderedDictionary new.
	errorMessages := OrderedDictionary new
]

{ #category : 'inspector' }
MCPTestResult >> inspectorOutcome: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Outcome'>

	"The counts come from the result itself, and the two message collections are what the
	 report dictionary carries to a client, so a reader sees exactly what the tool answered."

	^ (StSimpleInspectorBuilder on: aBuilder)
		key: 'Ran' value: self runCount printString;
		key: 'Passed' value: self expectedPasses size printString;
		key: 'Failed' value: self failures size printString;
		key: 'Errored' value: self errors size printString;
		key: 'Failure messages' value: (self failureMessages size printString , ' recorded');
		key: 'Error messages' value: (self errorMessages size printString , ' recorded');
		key: 'First failure' value: (self failureMessages
			ifEmpty: [ 'none' ]
			ifNotEmpty: [ :messages | messages first printString ]);
		key: 'First error' value: (self errorMessages
			ifEmpty: [ 'none' ]
			ifNotEmpty: [ :messages | messages first printString ]);
		table
]

{ #category : 'running' }
MCPTestResult >> runCase: aTestCase [
	| excClasses |
	excClasses := self class failure , self class skip , self class warning , self class error.
	[
		aTestCase announce: TestCaseStarted withResult: self.
		aTestCase runCaseManaged.
		aTestCase announce: TestCaseEnded withResult: self.
		self addPass: aTestCase
	] on: excClasses
	  do: [ :ex |
		(ex isKindOf: TestFailure) ifTrue: [
			failureMessages at: aTestCase selector asString put: ex messageText ].
		((ex isKindOf: Error) and: [ (ex isKindOf: TestFailure) not ]) ifTrue: [
			errorMessages at: aTestCase selector asString put: ex messageText ].
		ex sunitAnnounce: aTestCase toResult: self ]
]
