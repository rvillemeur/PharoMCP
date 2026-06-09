"
Log entry for MCP protocol initialize handshake requests.
"
Class {
	#name : 'MCPInitializeLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPInitializeLogEntry class >> toolName [
	^ 'initialize'
]

{ #category : 'accessing' }
MCPInitializeLogEntry >> requestArgument [
	^ '' 
]
