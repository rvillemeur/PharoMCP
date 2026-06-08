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
