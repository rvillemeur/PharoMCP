Class {
	#name : 'ReEmptyExceptionHandlerRuleTest',
	#superclass : 'TestCase',
	#instVars : [
		'rule'
	],
	#category : 'PharoMCP-Tests',
	#package : 'PharoMCP-Tests'
}

{ #category : 'running' }
ReEmptyExceptionHandlerRuleTest >> setUp [
	super setUp.
	rule := ReEmptyExceptionHandlerRule new
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testFiresOnEmptyHandlerNoTemps [
	| canary found |
	ReEmptyExceptionHandlerRuleTest compile: 'emptyHandlerCanary [ 1+1 ] on: Error do: [:e | ]' classified: 'private'.
	found := (ReCriticEngine critiquesOf: (ReEmptyExceptionHandlerRuleTest >> #emptyHandlerCanary))
		anySatisfy: [:c | [c rule isKindOf: ReEmptyExceptionHandlerRule] on: Error do: [:e | false]].
	ReEmptyExceptionHandlerRuleTest removeSelector: #emptyHandlerCanary.
	self assert: found
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testFiresOnEmptyHandlerWithTemps [
	| found |
	ReEmptyExceptionHandlerRuleTest compile: 'emptyHandlerCanary [ 1+1 ] on: Error do: [:e | | tmp | ]' classified: 'private'.
	found := (ReCriticEngine critiquesOf: (ReEmptyExceptionHandlerRuleTest >> #emptyHandlerCanary))
		anySatisfy: [:c | [c rule isKindOf: ReEmptyExceptionHandlerRule] on: Error do: [:e | false]].
	ReEmptyExceptionHandlerRuleTest removeSelector: #emptyHandlerCanary.
	self assert: found
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testGroupDefined [
	self assert: rule group isString.
	self deny: rule group isEmpty
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testNameDefined [
	self assert: rule name isString.
	self deny: rule name isEmpty
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testRationaleDefined [
	self assert: rule rationale isString.
	self deny: rule rationale isEmpty
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testSilentOnNoExceptionHandler [
	| found |
	ReEmptyExceptionHandlerRuleTest compile: 'noHandlerCanary ^ 1 + 1' classified: 'private'.
	found := (ReCriticEngine critiquesOf: (ReEmptyExceptionHandlerRuleTest >> #noHandlerCanary))
		anySatisfy: [:c | [c rule isKindOf: ReEmptyExceptionHandlerRule] on: Error do: [:e | false]].
	ReEmptyExceptionHandlerRuleTest removeSelector: #noHandlerCanary.
	self deny: found
]

{ #category : 'tests' }
ReEmptyExceptionHandlerRuleTest >> testSilentOnNonEmptyHandler [
	| found |
	ReEmptyExceptionHandlerRuleTest compile: 'handlerCanary [ 1+1 ] on: Error do: [:e | ^ nil ]' classified: 'private'.
	found := (ReCriticEngine critiquesOf: (ReEmptyExceptionHandlerRuleTest >> #handlerCanary))
		anySatisfy: [:c | [c rule isKindOf: ReEmptyExceptionHandlerRule] on: Error do: [:e | false]].
	ReEmptyExceptionHandlerRuleTest removeSelector: #handlerCanary.
	self deny: found
]
