Class {
	#name : 'MCPNullLoggerTest',
	#superclass : 'TestCase',
	#category : 'PharoMCP',
	#package : 'PharoMCP'
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
