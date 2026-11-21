"
Examples of MCPServer: a server built but not started, one that keeps the loopback interface and a token, and the window.

Also the entry point for running the server in an image: start, startOnPort:, stop and isRunning keep the running server in the image globals under #PharoMCPServer, so it survives a garbage collection.
"
Class {
	#name : 'MCPServerExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'running' }
MCPServerExamples class >> isRunning [

	^ (Smalltalk at: #PharoMCPServer ifAbsent: [ nil ])
		ifNil: [ false ]
		ifNotNil: [ :server | server isRunning ]
]

{ #category : 'examples' }
MCPServerExamples class >> openServerWindow [

	"Opens on a server that was built and not started, so the window can be read without
	 binding a port."

	^ MCPServerPresenter openWithServer: self server
]

{ #category : 'examples' }
MCPServerExamples class >> server [

	<sampleInstance>
	^ MCPServer onPort: MCPServer defaultPort
]

{ #category : 'examples' }
MCPServerExamples class >> serverBehindATokenOnLoopback [

	<sampleInstance>
	^ (MCPServer onPort: MCPServer defaultPort)
		bindLoopbackOnly;
		requireToken: 'a-long-random-string';
		yourself
]

{ #category : 'running' }
MCPServerExamples class >> start [

	^ self startOnPort: MCPServer defaultPort
]

{ #category : 'running' }
MCPServerExamples class >> startOnPort: aPort [

	| server |
	self stop.
	server := MCPServer onPort: aPort.
	server start.
	Smalltalk at: #PharoMCPServer put: server.
	^ server
]

{ #category : 'running' }
MCPServerExamples class >> stop [

	(Smalltalk at: #PharoMCPServer ifAbsent: [ nil ]) ifNotNil: [ :server | server stop ].
	Smalltalk globals removeKey: #PharoMCPServer ifAbsent: [ ]
]
