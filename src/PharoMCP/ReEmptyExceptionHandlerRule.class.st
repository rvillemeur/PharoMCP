"
Empty exception handler blocks hide potential bugs. The situation should be handled in a more robust way.

[  .... ]
	on: Error
	do: [  ]
	
having an empty block is a bad idea because the program silently fails.
"
Class {
	#name : 'ReEmptyExceptionHandlerRule',
	#superclass : 'ReAbstractRule',
	#category : 'PharoMCP-Rules',
	#package : 'PharoMCP',
	#tag : 'Rules'
}

{ #category : 'testing - interest' }
ReEmptyExceptionHandlerRule class >> checksMethod [
	^ true
]

{ #category : 'accessing' }
ReEmptyExceptionHandlerRule class >> group [
	^ self potentialBugsGroup
]

{ #category : 'accessing' }
ReEmptyExceptionHandlerRule class >> ruleName [
	^ 'Empty exception handler'
]

{ #category : 'manifest' }
ReEmptyExceptionHandlerRule class >> uniqueIdentifierName [
	^ 'ReEmptyExceptionHandlerRule'
]

{ #category : 'hooks' }
ReEmptyExceptionHandlerRule >> afterCheck: aNode mappings: mappingDict [
	| exception class |
	exception := mappingDict at: '`exception'.

	exception isVariable ifFalse: [ ^ false ].
	(class := aNode methodNode methodClass environment classNamed: exception name) ifNil: [ ^ false ].
	(class includesBehavior: Exception) ifFalse: [ ^ false ].
	(class includesBehavior: Notification) ifTrue: [ ^false ].

	^ true
]

{ #category : 'checking' }
ReEmptyExceptionHandlerRule >> basicCheck: aMethod [
	aMethod ast nodesDo: [ :node |
		(node isMessage and: [ node selector = #on:do: and: [
			node arguments last isBlock and: [
				node arguments last body statements isEmpty]]])
		ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'accessing' }
ReEmptyExceptionHandlerRule >> group [
	^ 'Coding Style'
]

{ #category : 'accessing' }
ReEmptyExceptionHandlerRule >> name [
	^ 'Empty exception handler'
]

{ #category : 'accessing' }
ReEmptyExceptionHandlerRule >> rationale [
	^ 'Empty exception handlers silently swallow errors, hiding bugs. Handle the exception or restructure the code.'
]
