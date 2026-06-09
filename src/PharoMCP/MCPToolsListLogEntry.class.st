"
Log entry for tools/list requests that enumerate available MCP tools.
"
Class {
	#name : 'MCPToolsListLogEntry',
	#superclass : 'MCPLogEntry',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'accessing' }
MCPToolsListLogEntry class >> toolName [
	^ 'tools/list'
]

{ #category : 'accessing' }
MCPToolsListLogEntry >> requestArgument [
	^ '' 
]
