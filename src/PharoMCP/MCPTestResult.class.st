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
