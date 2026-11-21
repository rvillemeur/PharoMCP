"
I test MCPLogEntryPresenter: that it fills the four texts of a log entry and clears them for nil, and that it resets a text presenter's cursor before replacing its string.
"
Class {
	#name : 'MCPLogEntryPresenterTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPLogEntryPresenterTest >> evalEntry [

	^ MCPLogEntry
		request: (NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'id' put: 1;
			at: 'method' put: 'tools/call';
			at: 'params' put: (Dictionary new
				at: 'name' put: 'evaluate_pharo';
				at: 'arguments' put: (Dictionary new at: 'code' put: '42'; yourself);
				yourself);
			yourself))
		response: (NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'id' put: 1;
			at: 'result' put: (Dictionary new
				at: 'content' put: (Array with: (Dictionary new
					at: 'type' put: 'text';
					at: 'text' put: '42';
					yourself));
				at: 'isError' put: false;
				yourself);
			yourself))
]

{ #category : 'private' }
MCPLogEntryPresenterTest >> notificationEntry [

	^ MCPLogEntry
		request: (NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'method' put: 'notifications/initialized';
			yourself))
		response: ''
]

{ #category : 'tests' }
MCPLogEntryPresenterTest >> testShowEntryFillsEveryTextFromTheEntry [

	| presenter entry |
	presenter := MCPLogEntryPresenter new.
	entry := self evalEntry.
	presenter showEntry: entry.
	self
		assert: (presenter textPresenters collect: [ :each | each text ]) asArray
		equals: {
			entry requestArgument.
			entry formattedRequestJson.
			entry extractedResponseText.
			entry formattedResponseJson }
]

{ #category : 'tests' }
MCPLogEntryPresenterTest >> testShowEntrySaysSoWhenTheResponseCarriesNoText [

	| presenter entry |
	presenter := MCPLogEntryPresenter new.
	entry := self notificationEntry.
	self assert: entry extractedResponseText isNil.
	presenter showEntry: entry.
	self assert: (presenter textPresenters third) text equals: '(no text content)'
]

{ #category : 'tests' }
MCPLogEntryPresenterTest >> testShowEntryWithNilClearsEveryText [

	| presenter |
	presenter := MCPLogEntryPresenter new.
	presenter showEntry: self evalEntry.
	presenter showEntry: nil.
	presenter textPresenters do: [ :each | self assert: each text isEmpty ]
]

{ #category : 'tests' }
MCPLogEntryPresenterTest >> testShowTextResetsTheCursorBeforeReplacingTheString [

	| stub |
	stub := MCPRecordingTextPresenterStub new.
	MCPLogEntryPresenter new showText: 'anything' in: stub.
	self assert: stub messages asArray equals: #( #cursorPositionIndex: #text: ).
	self assert: stub text equals: 'anything'
]
