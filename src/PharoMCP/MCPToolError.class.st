"
A tool call that cannot be carried out: no such class, no such selector, a name already taken. The request processor turns me into a tool result with isError set, carrying my messageText, so the model that called the tool reads a failure rather than a text that merely starts with the word Error. Signal me with MCPToolError signal: 'class not found: Foo' — the processor writes the Error prefix itself.
"
Class {
	#name : 'MCPToolError',
	#superclass : 'Error',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'inspector' }
MCPToolError >> inspectionAsToolResult: aBuilder [

	<inspectorPresentationOrder: 0 title: 'As a tool result'>
	"Built through the request processor rather than restated here, so the view cannot drift
	 from the response a client really reads. The isError flag is the point of this class."
	^ aBuilder newCode
		syntaxHighlight: false;
		text: (NeoJSONWriter toStringPretty: (MCPRequestProcessor new
			toolResult: 'Error: ' , self messageText asString
			isError: true
			id: 1));
		yourself
]
