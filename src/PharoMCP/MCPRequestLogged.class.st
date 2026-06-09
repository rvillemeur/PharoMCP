"
Announced when a new MCP request/response pair is captured by the logger. Carries the MCPLogEntry via #entry.
"
Class {
	#name : 'MCPRequestLogged',
	#superclass : 'MCPAnnouncement',
	#instVars : [
		'entry'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPRequestLogged >> entry [
	^ entry
]

{ #category : 'accessing' }
MCPRequestLogged >> entry: anEntry [
	entry := anEntry
]
