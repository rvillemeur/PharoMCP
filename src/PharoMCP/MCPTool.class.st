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

{ #category : 'annotations' }
MCPTool >> additive [

	^ self annotations: self additiveHints
]

{ #category : 'annotations' }
MCPTool >> additiveHints [

	"Changes the image but destroys nothing: it adds a class, a method or a package, or it
	 overwrites one the caller named. Running it twice leaves the same image."
	^ self hintsReadOnly: false destructive: false idempotent: true
]

{ #category : 'accessing' }
MCPTool >> annotations [

	^ annotations
]

{ #category : 'accessing' }
MCPTool >> annotations: aDictionary [

	annotations := aDictionary
]

{ #category : 'calling' }
MCPTool >> answersStructuredContent: aResult [

	"A tool that declares an outputSchema answers a dictionary when it succeeded, and a plain
	 string when it has an error to report, which belongs in the text block alone."
	^ self outputSchema notNil and: [ aResult isDictionary ]
]

{ #category : 'converting' }
MCPTool >> asDictionary [

	| dictionary |
	dictionary := Dictionary new
		at: 'name' put: self name;
		at: 'description' put: self description;
		at: 'inputSchema' put: self inputSchema;
		yourself.
	self title ifNotNil: [ :each | dictionary at: 'title' put: each ].
	self annotations ifNotNil: [ :each | dictionary at: 'annotations' put: each ].
	self outputSchema ifNotNil: [ :each | dictionary at: 'outputSchema' put: each ].
	^ dictionary
]

{ #category : 'calling' }
MCPTool >> call: arguments [

	"What the request processor sends. A subclass states its answer in execute:; the tools built
	 from a block answer through the block."
	^ self execute: arguments
]

{ #category : 'accessing' }
MCPTool >> description [
	^ description
]

{ #category : 'accessing' }
MCPTool >> description: aString [
	description := aString
]

{ #category : 'annotations' }
MCPTool >> destructive [

	^ self annotations: self destructiveHints
]

{ #category : 'annotations' }
MCPTool >> destructiveHints [

	"Removes code from the image, so a client asks its user before it calls the tool."
	^ self hintsReadOnly: false destructive: true idempotent: false
]

{ #category : 'calling' }
MCPTool >> execute: arguments [

	"The hook a subclass overrides. A tool built from a block answers through the block."
	^ handler value: arguments
]

{ #category : 'accessing' }
MCPTool >> handler [
	^ handler
]

{ #category : 'accessing' }
MCPTool >> handler: aBlock [
	handler := aBlock
]

{ #category : 'annotations' }
MCPTool >> hintsReadOnly: readOnlyBoolean destructive: destructiveBoolean idempotent: idempotentBoolean [

	"openWorldHint is false for every tool of this server: all of them act on the one local
	 image, none reaches a network or a service whose answer could change on its own."
	^ Dictionary new
		at: 'readOnlyHint' put: readOnlyBoolean;
		at: 'destructiveHint' put: destructiveBoolean;
		at: 'idempotentHint' put: idempotentBoolean;
		at: 'openWorldHint' put: false;
		yourself
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

{ #category : 'inspecting' }
MCPTool >> inspectionSchema: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Schema'>
	^ aBuilder newCode
		syntaxHighlight: false;
		text: (NeoJSONWriter toStringPretty: self inputSchema);
		yourself
]

{ #category : 'calling' }
MCPTool >> missingRequiredArgumentsIn: arguments [

	"The names the tool's own schema requires and the call did not carry. The specification asks
	 for these to come back as a tool error rather than a protocol error, so the model reading
	 the answer can correct its own call."
	| required |
	required := self inputSchema at: 'required' ifAbsent: [ ^ OrderedCollection new ].
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

{ #category : 'annotations' }
MCPTool >> readOnly [

	^ self annotations: self readOnlyHints
]

{ #category : 'annotations' }
MCPTool >> readOnlyHint: readOnlyBoolean destructiveHint: destructiveBoolean idempotentHint: idempotentBoolean [

	^ self annotations: (self
		hintsReadOnly: readOnlyBoolean
		destructive: destructiveBoolean
		idempotent: idempotentBoolean)
]

{ #category : 'annotations' }
MCPTool >> readOnlyHints [

	"Reads the image and changes nothing, so a client may call it without asking its user."
	^ self hintsReadOnly: true destructive: false idempotent: true
]

{ #category : 'schemas' }
MCPTool >> schemaArrayOfMessagesDescribedAs: aDescription [

	^ Dictionary new
		at: 'type' put: 'array';
		at: 'description' put: aDescription;
		at: 'items' put: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'selector' put: (self schemaPropertyOfType: 'string' describedAs: 'Test method selector');
				at: 'message' put: (self schemaPropertyOfType: 'string' describedAs: 'What the test reported');
				yourself);
			yourself);
		yourself
]

{ #category : 'schemas' }
MCPTool >> schemaPropertyOfType: aTypeName describedAs: aDescription [

	^ Dictionary new
		at: 'type' put: aTypeName;
		at: 'description' put: aDescription;
		yourself
]

{ #category : 'schemas' }
MCPTool >> schemaPropertyOneOf: allowedValues describedAs: aDescription [

	^ Dictionary new
		at: 'type' put: 'string';
		at: 'enum' put: allowedValues;
		at: 'description' put: aDescription;
		yourself
]

{ #category : 'schemas' }
MCPTool >> schemaSideProperty [

	"The side argument six tools take. It means the same in each of them, so it reads the same."
	^ self
		schemaPropertyOneOf: #( 'instance' 'class' )
		describedAs: 'Whether the method is on the instance side or the class side. Defaults to instance.'
]

{ #category : 'schemas' }
MCPTool >> schemaWithProperties: propertyAssociations required: requiredNames [

	"The JSON Schema shape every tool declares. A tool states the properties it takes and the
	 names a call must carry, and nothing else."
	^ Dictionary new
		at: 'type' put: 'object';
		at: 'properties' put: propertyAssociations asDictionary;
		at: 'required' put: requiredNames;
		yourself
]

{ #category : 'accessing' }
MCPTool >> title [

	^ title
]

{ #category : 'accessing' }
MCPTool >> title: aString [

	title := aString
]
