"
Entry point for running the PharoMCP server.

## Starting

    MCPExample start               -- uses port 7777
    MCPExample startOnPort: 8888   -- custom port

The server is stored in the image globals under #PharoMCPServer so it survives
garbage collection. Stop it explicitly before starting again.

    MCPExample stop
    MCPExample isRunning

## Connecting Claude Code

Register the server with Claude Code (run once in a terminal):

    claude mcp add --transport http pharo http://127.0.0.1:7777/

If Claude Code runs inside a container and Pharo runs on the host, use the
host gateway address instead of 127.0.0.1:

    claude mcp remove pharo
    claude mcp add --transport http pharo http://host.docker.internal:7777/

Verify the connection inside a Claude Code session with /mcp.

## Troubleshooting

Port already in use — stop any running instance:
    MCPExample stop.
    ZnServer allInstances do: [:s | [s stop] on: Error do: []].

Server appears running but not responding:
    MCPExample isRunning.          -- should return true
    ZnServer allInstances select: [:s | s isRunning].

Verify the port is bound (run in a terminal on the host):
    ss -tlnp | grep 7777

ConnectionRefused from Claude Code despite port being bound:
- localhost may resolve to ::1 (IPv6) while Pharo listens on 0.0.0.0 (IPv4).
  Use 127.0.0.1 explicitly in the MCP URL.
- Inside a container, localhost refers to the container loopback, not the host.
  Find the host address: getent hosts host.docker.internal
  Then use that IP in the MCP URL.

Test the server directly from a terminal:
    curl -s -X POST http://127.0.0.1:7777/
         -H Content-Type:application/json
         -d {jsonrpc:2.0,id:1,method:initialize,params:{}}
"
Class {
	#name : 'MCPExample',
	#superclass : 'Object',
	#category : 'PharoMCP-Example',
	#package : 'PharoMCP',
	#tag : 'Example'
}

{ #category : 'testing' }
MCPExample class >> isRunning [
<sampleInstance>
	^ (Smalltalk at: #PharoMCPServer ifAbsent: [ nil ])
		ifNil: [ false ]
		ifNotNil: [ :s | s isRunning ]
]

{ #category : 'start-stop' }
MCPExample class >> start [
<sampleInstance>
	^ self startOnPort: 7777
]

{ #category : 'start-stop' }
MCPExample class >> startOnPort: aPort [
	| server |
	self stop.
	server := MCPServer onPort: aPort.
	server start.
	Smalltalk at: #PharoMCPServer put: server.
	^ server
]

{ #category : 'start-stop' }
MCPExample class >> stop [
<sampleInstance>
	(Smalltalk at: #PharoMCPServer ifAbsent: [ nil ]) ifNotNil: [ :s |
		[ s stop ] on: Error do: [ ] ].
	Smalltalk removeKey: #PharoMCPServer ifAbsent: [ ]
]

{ #category : 'see class side' }
MCPExample >> seeClassSide [ 
]
