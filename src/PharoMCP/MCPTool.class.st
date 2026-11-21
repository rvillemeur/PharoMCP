"
Represents a single MCP tool — a named, described function that an LLM can invoke.

Created via the class-side constructor:
    MCPTool
        name: 'my_tool'
        description: 'What it does'
        schema: (Dictionary new at: 'type' put: 'object'; yourself)
        handler: [ :args | 'result string' ]

The handler block receives a Dictionary of string-keyed arguments and must return a String (or any object, which is coerced via printString by MCPRequestProcessor).

The inputSchema follows JSON Schema format and is advertised to clients in tools/list responses.

Key messages:
- call: args       invoke the handler
- asDictionary     serialize for tools/list response
"
Class {
	#name : 'MCPTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'inputSchema',
		'handler',
		'title',
		'annotations',
		'outputSchema'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'instance creation' }
MCPTool class >> name: aName description: aDescription schema: aSchema handler: aBlock [
	^ self new
		name: aName;
		description: aDescription;
		inputSchema: aSchema;
		handler: aBlock;
		yourself
]

{ #category : 'annotating' }
MCPTool >> additive [

	"Changes the image but destroys nothing: it adds a class, a method or a package, or it
	 overwrites one the caller named. Running it twice leaves the same image."

	^ self readOnlyHint: false destructiveHint: false idempotentHint: true
]

{ #category : 'accessing' }
MCPTool >> annotations [

	^ annotations
]

{ #category : 'accessing' }
MCPTool >> annotations: aDictionary [

	annotations := aDictionary
]

{ #category : 'converting' }
MCPTool >> asDictionary [

	| dictionary |
	dictionary := Dictionary new
		at: 'name' put: name;
		at: 'description' put: description;
		at: 'inputSchema' put: inputSchema;
		yourself.
	title ifNotNil: [ dictionary at: 'title' put: title ].
	annotations ifNotNil: [ dictionary at: 'annotations' put: annotations ].
	outputSchema ifNotNil: [ dictionary at: 'outputSchema' put: outputSchema ].
	^ dictionary
]

{ #category : 'executing' }
MCPTool >> call: arguments [
	^ handler value: arguments
]

{ #category : 'accessing' }
MCPTool >> description [
	^ description
]

{ #category : 'accessing' }
MCPTool >> description: aString [
	description := aString
]

{ #category : 'annotating' }
MCPTool >> destructive [

	"Removes code from the image, so a client asks its user before it calls the tool."

	^ self readOnlyHint: false destructiveHint: true idempotentHint: false
]

{ #category : 'accessing' }
MCPTool >> handler [
	^ handler
]

{ #category : 'accessing' }
MCPTool >> handler: aBlock [
	handler := aBlock
]

{ #category : 'accessing' }
MCPTool >> inputSchema [
	^ inputSchema
]

{ #category : 'accessing' }
MCPTool >> inputSchema: aDictionary [
	inputSchema := aDictionary
]

{ #category : 'inspector' }
MCPTool >> inspectionAsSentToClient: aBuilder [

	<inspectorPresentationOrder: 1 title: 'As sent'>

	^ aBuilder newCode
		syntaxHighlight: false;
		text: (NeoJSONWriter toStringPretty: self asDictionary);
		yourself
]

{ #category : 'inspector' }
MCPTool >> inspectionSchema: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Schema'>
	^ aBuilder newCode
		syntaxHighlight: false;
		text: (NeoJSONWriter toStringPretty: inputSchema);
		yourself
]

{ #category : 'validating' }
MCPTool >> missingRequiredArgumentsIn: arguments [

	"The names the tool's own schema requires and the call did not carry. The specification asks
	 for these to come back as a tool error rather than a protocol error, so the model reading
	 the answer can correct its own call."

	| required |
	required := inputSchema at: 'required' ifAbsent: [ ^ OrderedCollection new ].
	^ (required reject: [ :each | arguments includesKey: each ]) asOrderedCollection
]

{ #category : 'accessing' }
MCPTool >> name [
	^ name
]

{ #category : 'accessing' }
MCPTool >> name: aString [
	name := aString
]

{ #category : 'accessing' }
MCPTool >> outputSchema [

	^ outputSchema
]

{ #category : 'accessing' }
MCPTool >> outputSchema: aDictionary [

	outputSchema := aDictionary
]

{ #category : 'annotating' }
MCPTool >> readOnly [

	"Reads the image and changes nothing, so a client may call it without asking its user."

	^ self readOnlyHint: true destructiveHint: false idempotentHint: true
]

{ #category : 'annotating' }
MCPTool >> readOnlyHint: readOnlyBoolean destructiveHint: destructiveBoolean idempotentHint: idempotentBoolean [

	"openWorldHint is false for every tool of this server: all of them act on the one local
	 image, none reaches a network or a service whose answer could change on its own."

	^ self annotations: (Dictionary new
		at: 'readOnlyHint' put: readOnlyBoolean;
		at: 'destructiveHint' put: destructiveBoolean;
		at: 'idempotentHint' put: idempotentBoolean;
		at: 'openWorldHint' put: false;
		yourself)
]

{ #category : 'accessing' }
MCPTool >> title [

	^ title
]

{ #category : 'accessing' }
MCPTool >> title: aString [

	title := aString
]
