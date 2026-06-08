"
Detail view for a single MCPLogEntry. Shows the raw request JSON above and
the response JSON below in read-only text areas.

Used as an embedded sub-presenter inside MCPServerPresenter.
"
Class {
	#name : 'MCPLogEntryPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'requestArgumentText',
		'requestRawText',
		'responseText',
		'responseRawText',
		'requestNotebook',
		'responseNotebook'
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
			add: requestNotebook;
			yourself);
		add: (SpBoxLayout newTopToBottom
			add: (self newLabel label: 'Response:') expand: false;
			add: responseNotebook;
			yourself);
		yourself
]

{ #category : 'initialization' }
MCPLogEntryPresenter >> initializePresenters [
	requestArgumentText := self newText beNotEditable; yourself.
	requestRawText := self newText beNotEditable; yourself.
	responseText := self newText beNotEditable; yourself.
	responseRawText := self newText beNotEditable; yourself.
	requestNotebook := self newNotebook.
	requestNotebook
		addPage: (SpNotebookPage title: 'Argument' provider: [ requestArgumentText ]);
		addPage: (SpNotebookPage title: 'Raw' provider: [ requestRawText ]).
	responseNotebook := self newNotebook.
	responseNotebook
		addPage: (SpNotebookPage title: 'Text' provider: [ responseText ]);
		addPage: (SpNotebookPage title: 'Raw' provider: [ responseRawText ])
]

{ #category : 'api' }
MCPLogEntryPresenter >> showEntry: anEntry [
	| extracted |
	anEntry isNil ifTrue: [
		requestArgumentText text: ''.
		requestRawText text: ''.
		responseText text: ''.
		responseRawText text: ''.
		^ self ].
	requestArgumentText text: anEntry requestArgument.
	requestRawText text: anEntry formattedRequestJson.
	extracted := anEntry extractedResponseText.
	responseText text: (extracted ifNil: [ '(no text content)' ]).
	responseRawText text: anEntry formattedResponseJson
]
