"
Holds MCPNullLogger to answering the logger protocol while recording nothing, which is what a server with logging switched off uses.
"
Class {
	#name : 'MCPNullLoggerTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
MCPNullLoggerTest >> testClearIsNoOp [
	| logger |
	logger := MCPNullLogger new.
	logger clear.
	self assert: logger entries isEmpty
]

{ #category : 'tests' }
MCPNullLoggerTest >> testEntriesAlwaysEmpty [
	self assert: MCPNullLogger new entries isEmpty
]

{ #category : 'tests' }
MCPNullLoggerTest >> testExportAsJsonReturnsEmptyArray [
	self assert: MCPNullLogger new exportAsJson equals: '[]'
]

{ #category : 'tests' }
MCPNullLoggerTest >> testIsActiveReturnsFalse [
	self deny: MCPNullLogger new isActive
]

{ #category : 'tests' }
MCPNullLoggerTest >> testLogReturnsNil [
	self assert: (MCPNullLogger new log: '{}' response: '{}') isNil
]
