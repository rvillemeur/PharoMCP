"
Detail view for a single MCPLogEntry. Shows the raw request JSON above and
the response JSON below in read-only text areas.

Used as an embedded sub-presenter inside MCPServerPresenter.
"
Class {
	#name : 'MCPLogEntryPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'requestText',
		'responseText'
	],
	#category : 'PharoMCP-UI',
	#package : 'PharoMCP',
	#tag : 'UI'
}

{ #category : 'layout' }
MCPLogEntryPresenter >> defaultLayout [
	^ SpPanedLayout newTopToBottom
		positionOfSlider: 50;
		add: (SpBoxLayout newTopToBottom
			add: (self newLabel label: 'Request:') expand: false;
			add: requestText;
			yourself);
		add: (SpBoxLayout newTopToBottom
			add: (self newLabel label: 'Response:') expand: false;
			add: responseText;
			yourself);
		yourself
]

{ #category : 'initialization' }
MCPLogEntryPresenter >> initializePresenters [
	requestText := self newText
		beNotEditable;
		yourself.
	responseText := self newText
		beNotEditable;
		yourself.
]

{ #category : 'api' }
MCPLogEntryPresenter >> showEntry: anEntry [
	anEntry isNil ifTrue: [
		requestText text: ''.
		responseText text: ''.
		^ self ].
	requestText text: anEntry formattedRequestJson.
	responseText text: anEntry formattedResponseJson
]
