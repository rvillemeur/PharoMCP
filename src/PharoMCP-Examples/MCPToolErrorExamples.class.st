"
The examples of MCPToolError, the failure a tool helper signals. toolError answers a signalled and caught instance, so the inspector shows the error object itself rather than opening a debugger; open it to see the tool result a client reads for a failed call.
"
Class {
	#name : 'MCPToolErrorExamples',
	#superclass : 'Object',
	#category : 'PharoMCP-Examples',
	#package : 'PharoMCP-Examples'
}

{ #category : 'examples' }
MCPToolErrorExamples class >> toolError [

	<sampleInstance>
	"Signalled and caught: an unraised exception carries no signal context, and signalling it
	 outside a handler would open a debugger instead of answering the instance."
	^ [ MCPToolError signal: 'class not found: NoSuchClassXYZ' ]
		on: MCPToolError
		do: [ :e | e ]
]
