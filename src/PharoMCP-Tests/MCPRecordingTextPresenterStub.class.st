"
I stand in for a Spec text presenter in a test and record, in order, the messages MCPLogEntryPresenter sends me. The order is what the test is about: the cursor must be reset before the string is replaced. #messages answers the selectors as they arrived, #text the last string set.
"
Class {
	#name : 'MCPRecordingTextPresenterStub',
	#superclass : 'Object',
	#instVars : [
		'messages',
		'text'
	],
	#category : 'PharoMCP-Tests-Fixtures',
	#package : 'PharoMCP-Tests',
	#tag : 'Fixtures'
}

{ #category : 'recording' }
MCPRecordingTextPresenterStub >> cursorPositionIndex: anInteger [

	messages add: #cursorPositionIndex:
]

{ #category : 'initialization' }
MCPRecordingTextPresenterStub >> initialize [

	super initialize.
	messages := OrderedCollection new
]

{ #category : 'accessing' }
MCPRecordingTextPresenterStub >> messages [

	^ messages
]

{ #category : 'accessing' }
MCPRecordingTextPresenterStub >> text [

	^ text
]

{ #category : 'recording' }
MCPRecordingTextPresenterStub >> text: aString [

	messages add: #text:.
	text := aString
]
