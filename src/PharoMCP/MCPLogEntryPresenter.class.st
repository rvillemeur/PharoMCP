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
		positionOfSlider: 250;
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

{ #category : 'updating' }
MCPLogEntryPresenter >> showEntry: anEntry [

	anEntry ifNil: [ ^ self textPresenters do: [ :each | self showText: '' in: each ] ].
	self showText: anEntry requestArgument in: requestArgumentText.
	self showText: anEntry formattedRequestJson in: requestRawText.
	self showText: (anEntry extractedResponseText ifNil: [ '(no text content)' ]) in: responseText.
	self showText: anEntry formattedResponseJson in: responseRawText
]

{ #category : 'updating' }
MCPLogEntryPresenter >> showText: aString in: aTextPresenter [

	"Move the cursor to the start before the string changes. Rubric replaces the paragraph's
	 string first and resets the cursor after, and a redraw caught between the two reads the old
	 cursor against the new string: RubOpeningClosingDelimiterDecorator >> drawOn: indexes
	 #pointIndex - 1 with no bound, so a shorter string raises SubscriptOutOfBounds and Morphic
	 paints the widget red. A nested render loop, such as the one a Metacello warning dialog
	 drives, is enough to catch that instant."

	aTextPresenter cursorPositionIndex: 1.
	aTextPresenter text: aString
]

{ #category : 'accessing' }
MCPLogEntryPresenter >> textPresenters [

	^ { requestArgumentText . requestRawText . responseText . responseRawText }
]
