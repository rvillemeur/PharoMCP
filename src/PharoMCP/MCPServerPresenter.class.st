"
GUI for the PharoMCP server. Shows server/logging status, live log of MCP
interactions, and a detail pane for the selected entry.

Open with:
    MCPServerPresenter open
    MCPServerPresenter openWithServer: myServer
"
Class {
	#name : 'MCPServerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'serverButton',
		'loggingButton',
		'clearButton',
		'logList',
		'detailPresenter',
		'server'
	],
	#category : 'PharoMCP-UI',
	#package : 'PharoMCP',
	#tag : 'UI'
}

{ #category : 'instance creation' }
MCPServerPresenter class >> open [
	^ self openWithServer: (Smalltalk
		at: #PharoMCPServer
		ifAbsent: [ MCPServer default ])
]

{ #category : 'instance creation' }
MCPServerPresenter class >> openWithServer: aServer [
	| p |
	p := self new.
	p server: aServer.
	p open.
	^ p
]

{ #category : 'private' }
MCPServerPresenter >> addLogEntry: anEntry [
	| items |
	items := server logger entries asArray.
	logList items: items.
	items isEmpty ifFalse: [ logList selectIndex: items size ].
	detailPresenter showEntry: anEntry
]

{ #category : 'private' }
MCPServerPresenter >> clearLog [
	server logger clear.
	self refreshLog.
	detailPresenter showEntry: nil
]

{ #category : 'layout' }
MCPServerPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: (SpBoxLayout newLeftToRight
			add: serverButton expand: false;
			add: loggingButton expand: false;
			add: clearButton expand: false;
			yourself) expand: false;
		add: (SpPanedLayout newLeftToRight
			positionOfSlider: 40;
			add: logList;
			add: detailPresenter;
			yourself);
		yourself
]

{ #category : 'initialization' }
MCPServerPresenter >> initializePresenters [
	serverButton := self newButton
		label: 'Start Server';
		yourself.
	loggingButton := self newButton
		label: 'Start Logging';
		yourself.
	clearButton := self newButton
		label: 'Clear Log';
		action: [ self clearLog ];
		yourself.
	logList := self newTable.
	logList
		addColumn: (SpStringTableColumn
			title: 'Method'
			evaluated: [ :e | e displayMethod ]);
		addColumn: (SpStringTableColumn
			title: 'Args'
			evaluated: [ :e | e displayArgs ]);
		whenSelectedItemChangedDo: [ :item |
			item ifNotNil: [ detailPresenter showEntry: item ] ].
	detailPresenter := self instantiate: MCPLogEntryPresenter.
]

{ #category : 'initialization' }
MCPServerPresenter >> initializeWindow: aWindow [
	aWindow
		title: self windowTitle;
		initialExtent: 960 @ 580;
		whenOpenedDo: [
			self updateServerButton.
			self updateLoggingButton.
			self refreshLog.
			self subscribeToAnnouncements ];
		whenClosedDo: [ self unsubscribeFromAnnouncements ]
]

{ #category : 'private' }
MCPServerPresenter >> refreshLog [
	logList items: server logger entries asArray
]

{ #category : 'accessing' }
MCPServerPresenter >> server [
	^ server
]

{ #category : 'accessing' }
MCPServerPresenter >> server: aServer [
	server := aServer
]

{ #category : 'private' }
MCPServerPresenter >> startLogging [
	server startLogging
]

{ #category : 'private' }
MCPServerPresenter >> startServer [
	server start
]

{ #category : 'private' }
MCPServerPresenter >> stopLogging [
	server stopLogging
]

{ #category : 'private' }
MCPServerPresenter >> stopServer [
	server stop
]

{ #category : 'private' }
MCPServerPresenter >> subscribeToAnnouncements [
	server announcer
		when: MCPServerStarted
		do: [ UIManager default defer: [
				self updateServerButton.
				self updateTitle ] ]
		for: self;
		when: MCPServerStopped
		do: [ UIManager default defer: [
				self updateServerButton.
				self updateTitle ] ]
		for: self;
		when: MCPLoggingStarted
		do: [ UIManager default defer: [ self updateLoggingButton ] ]
		for: self;
		when: MCPLoggingStopped
		do: [ UIManager default defer: [ self updateLoggingButton ] ]
		for: self;
		when: MCPRequestLogged
		do: [ :ann |
			| entry |
			entry := ann entry.
			UIManager default defer: [ self addLogEntry: entry ] ]
		for: self
]

{ #category : 'private' }
MCPServerPresenter >> unsubscribeFromAnnouncements [
	server announcer unsubscribe: self
]

{ #category : 'private' }
MCPServerPresenter >> updateLoggingButton [
	server isLogging
		ifTrue: [
			loggingButton
				label: 'Stop Logging';
				action: [ self stopLogging ] ]
		ifFalse: [
			loggingButton
				label: 'Start Logging';
				action: [ self startLogging ] ]
]

{ #category : 'private' }
MCPServerPresenter >> updateServerButton [
	server isRunning
		ifTrue: [
			serverButton
				label: 'Stop Server';
				action: [ self stopServer ] ]
		ifFalse: [
			serverButton
				label: 'Start Server';
				action: [ self startServer ] ]
]

{ #category : 'private' }
MCPServerPresenter >> updateTitle [
	self withWindowDo: [ :w | w title: self windowTitle ]
]

{ #category : 'private' }
MCPServerPresenter >> windowTitle [
	server isNil ifTrue: [ ^ 'PharoMCP Server' ].
	^ 'PharoMCP Server — ' ,
		(server isRunning
			ifTrue: [ 'running on port ' , server port printString ]
			ifFalse: [ 'not running' ])
]
