"
Holds MCPRequestProcessor to the JSON-RPC and MCP rules: version negotiation, ping, tool results, tool errors and the protocol errors.
"
Class {
	#name : 'MCPRequestProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'processor'
	],
	#category : 'PharoMCP-Tests-Tests',
	#package : 'PharoMCP-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
MCPRequestProcessorTest >> assertToolError: aToolName with: anArgumentDictionary [

	"A failing tool call must answer isError true. A text that says Error with the flag unset
	 reads as a success to the model that called the tool."

	| real response result |
	real := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: real.
	response := real processRawRequest: (self request: 'tools/call' id: 11 params: (Dictionary new
		at: 'name' put: aToolName;
		at: 'arguments' put: anArgumentDictionary;
		yourself)).
	result := (self parse: response) at: 'result'.
	self assert: (result at: 'isError') description: aToolName , ' answered isError false'.
	^ ((result at: 'content') first at: 'text')
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> completionFor: aReference argument: aName value: aValue [

	| params response |
	params := Dictionary new
		at: 'ref' put: aReference;
		at: 'argument' put: (Dictionary new
			at: 'name' put: aName;
			at: 'value' put: aValue;
			yourself);
		yourself.
	response := processor processRawRequest: (self request: 'completion/complete' id: 7 params: params).
	^ ((self parse: response) at: 'result') at: 'completion'
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> initializeResultWithVersion: aStringOrNil [

	| params response |
	params := Dictionary new.
	aStringOrNil ifNotNil: [ :version | params at: 'protocolVersion' put: version ].
	response := processor processRawRequest: (self request: 'initialize' id: 1 params: params).
	^ (self parse: response) at: 'result'
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> initializeWithVersion: aStringOrNil [

	^ (self initializeResultWithVersion: aStringOrNil) at: 'protocolVersion'
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> parse: jsonString [
	^ NeoJSONReader fromString: jsonString
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> request: method id: id params: params [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'method' put: method;
		at: 'params' put: params;
		yourself)
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> resourceReference: aUri [

	^ Dictionary new
		at: 'type' put: 'ref/resource';
		at: 'uri' put: aUri;
		yourself
]

{ #category : 'helpers' }
MCPRequestProcessorTest >> resultOf: method params: params [

	| response |
	response := processor processRawRequest: (self request: method id: 9 params: params).
	^ (self parse: response) at: 'result'
]

{ #category : 'running' }
MCPRequestProcessorTest >> setUp [
	super setUp.
	processor := MCPRequestProcessor new.
	processor registerTool: (MCPTool
		name: 'echo'
		description: 'Returns the input text unchanged'
		schema: Dictionary new
		handler: [ :args | args at: 'text' ifAbsent: [ '' ] ]).
	processor registerTool: (MCPTool
		name: 'add'
		description: 'Adds two integers'
		schema: Dictionary new
		handler: [ :args | ((args at: 'a') + (args at: 'b')) printString ])
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testCompletionAnswersClassNames [

	| completion values |
	completion := self
		completionFor: (self resourceReference: 'pharo://class/')
		argument: 'className'
		value: 'MCPRequestProc'.
	values := completion at: 'values'.
	self assert: (values includes: 'MCPRequestProcessor').
	self assert: (values includes: 'MCPRequestProcessorTest').
	self assert: values equals: values asSortedCollection asArray.
	self deny: (completion at: 'hasMore')
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testCompletionAnswersPackageNames [

	| values |
	values := (self
		completionFor: (self resourceReference: 'pharo://package/')
		argument: 'packageName'
		value: 'PharoMCP') at: 'values'.
	self assert: (values includes: 'PharoMCP').
	self assert: (values includes: 'PharoMCP-Tests').
	self deny: (values anySatisfy: [ :each | (each beginsWith: 'PharoMCP') not ])
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testCompletionAnswersSelectors [

	| values |
	values := (self
		completionFor: (self resourceReference: 'pharo://selector/')
		argument: 'selector'
		value: 'inspectorRequestMapp') at: 'values'.
	self assert: (values includes: 'inspectorRequestMapping:').
	self assert: (values includes: 'inspectorRequestMappingContext:')
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testCompletionIsBoundedAndSaysSo [

	"The specification caps a completion at 100 values, so a short prefix must say that more
	 exist rather than answer thousands."

	| completion |
	completion := self
		completionFor: (self resourceReference: 'pharo://class/')
		argument: 'className'
		value: ''.
	self assert: (completion at: 'values') size equals: MCPRequestProcessor maximumCompletionValues.
	self assert: (completion at: 'hasMore').
	self assert: (completion at: 'total') > MCPRequestProcessor maximumCompletionValues
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testCompletionOfUnknownReferenceIsEmpty [

	| completion |
	completion := self
		completionFor: (self resourceReference: 'pharo://nothing/')
		argument: 'whatever'
		value: 'M'.
	self assert: (completion at: 'values') isEmpty.
	self assert: (completion at: 'total') equals: 0.
	self deny: (completion at: 'hasMore')
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testEveryRequiredArgumentIsRejectedBeforeTheHandlerRuns [

	"The guard lives in the processor, once, for every tool. A factory repeating it inside its
	 own handler block writes code the handler can never reach."
	| real |
	real := MCPRequestProcessor new.
	MCPPharoTools registerToolsWith: real.
	real tools valuesDo: [ :tool |
		| required response result |
		required := tool inputSchema at: 'required' ifAbsent: [ #() ].
		required ifNotEmpty: [
			response := real processRawRequest: (self request: 'tools/call' id: 12 params: (Dictionary new
				at: 'name' put: tool name;
				at: 'arguments' put: Dictionary new;
				yourself)).
			result := (self parse: response) at: 'result'.
			self
				assert: (result at: 'isError')
				description: tool name , ' answered isError false for a call with no arguments'.
			required do: [ :each |
				self
					assert: (((result at: 'content') first at: 'text') includesSubstring: each)
					description: tool name , ' did not name the missing argument ' , each ] ] ]
]

{ #category : 'tests - tools' }
MCPRequestProcessorTest >> testEveryToolSaysSoWhenItFails [

	| missing |
	missing := 'NoSuchClassXYZ'.
	{ 'class_definition' -> (Dictionary new at: 'className' put: missing; yourself).
	'class_hierarchy' -> (Dictionary new at: 'class_name' put: missing; yourself).
	'class_comment' -> (Dictionary new at: 'class_name' put: missing; yourself).
	'list_methods' -> (Dictionary new at: 'className' put: missing; yourself).
	'method_source' -> (Dictionary new at: 'className' put: missing; at: 'methodName' put: 'foo'; yourself).
	'class_remove' -> (Dictionary new at: 'class_name' put: missing; yourself).
	'class_rename' -> (Dictionary new at: 'old_name' put: missing; at: 'new_name' put: 'AnyName'; yourself).
	'delete_method' -> (Dictionary new at: 'class_name' put: missing; at: 'selector' put: 'foo'; yourself).
	'run_tests' -> (Dictionary new at: 'class_name' put: missing; yourself).
	'run_critics' -> (Dictionary new at: 'class_name' put: missing; yourself).
	'search_source' -> (Dictionary new at: 'pattern' put: 'foo'; at: 'class_name' put: missing; yourself).
	'package_remove' -> (Dictionary new at: 'package' put: 'NoSuchPackageXYZ'; yourself) }
		do: [ :each |
			| text |
			text := self assertToolError: each key with: each value.
			self assert: (text beginsWith: 'Error') description: each key , ' answered ' , text ]
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeAnswersLatestForUnknownVersion [

	self
		assert: (self initializeWithVersion: '1999-01-01')
		equals: MCPRequestProcessor latestProtocolVersion
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeAnswersLatestWhenClientSendsNoVersion [

	self
		assert: (self initializeWithVersion: nil)
		equals: MCPRequestProcessor latestProtocolVersion
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeCapabilitiesIncludeTools [
	| response result |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: Dictionary new).
	result := (self parse: response) at: 'result'.
	self assert: ((result at: 'capabilities') includesKey: 'tools')
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeCarriesInstructions [

	| instructions |
	instructions := (self initializeResultWithVersion: '2025-11-25') at: 'instructions'.
	self assert: instructions isString.
	self deny: instructions isEmpty
]

{ #category : 'tests - completion' }
MCPRequestProcessorTest >> testInitializeDeclaresCompletionsCapability [

	| capabilities |
	capabilities := (self initializeResultWithVersion: nil) at: 'capabilities'.
	self assert: (capabilities includesKey: 'completions')
]

{ #category : 'tests - prompts' }
MCPRequestProcessorTest >> testInitializeDeclaresPromptsCapability [

	| capabilities |
	capabilities := (self initializeResultWithVersion: nil) at: 'capabilities'.
	self assert: (capabilities includesKey: 'prompts')
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testInitializeDeclaresResourcesCapability [

	| capabilities |
	capabilities := (self initializeResultWithVersion: nil) at: 'capabilities'.
	self assert: (capabilities includesKey: 'resources')
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testInitializeEchoesSupportedVersionRequestedByClient [

	self assert: (self initializeWithVersion: '2025-06-18') equals: '2025-06-18'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeResponseHasCorrectId [
	| response dict |
	response := processor processRawRequest:
		(self request: 'initialize' id: 42 params: Dictionary new).
	dict := self parse: response.
	self assert: (dict at: 'id') equals: 42.
	self assert: (dict at: 'jsonrpc') equals: '2.0'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeReturnsProtocolVersion [
	| response result |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: (Dictionary new
			at: 'protocolVersion' put: '2024-11-05';
			at: 'capabilities' put: Dictionary new;
			at: 'clientInfo' put: (Dictionary new at: 'name' put: 'test'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	self assert: (result at: 'protocolVersion') equals: '2024-11-05'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testInitializeReturnsServerInfo [
	| response result serverInfo |
	response := processor processRawRequest:
		(self request: 'initialize' id: 1 params: Dictionary new).
	result := (self parse: response) at: 'result'.
	serverInfo := result at: 'serverInfo'.
	self assert: (serverInfo at: 'name') equals: 'PharoMCP'.
	self assert: (serverInfo includesKey: 'version')
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testLongResultIsTruncatedWithItsSizeStated [

	| size response text |
	size := MCPRequestProcessor maximumResultSize + 500.
	processor registerTool: (MCPTool
		name: 'long'
		description: 'Answers a long string'
		schema: Dictionary new
		handler: [ :args | String new: size withAll: $x ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'long';
		at: 'arguments' put: Dictionary new;
		yourself)).
	text := (((self parse: response) at: 'result') at: 'content') first at: 'text'.
	self assert: (text beginsWith: (String new: MCPRequestProcessor maximumResultSize withAll: $x)).
	self assert: (text endsWith: '(truncated, ' , size printString , ' characters)')
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testMissingRequiredArgumentIsToolError [

	| response result called |
	called := false.
	processor registerTool: (MCPTool
		name: 'needs_text'
		description: 'Needs a text argument'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'text' put: (Dictionary new at: 'type' put: 'string'; yourself);
				yourself);
			at: 'required' put: #( 'text' );
			yourself)
		handler: [ :args | called := true. args at: 'text' ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'needs_text';
		at: 'arguments' put: Dictionary new;
		yourself)).
	result := (self parse: response) at: 'result'.
	self deny: called.
	self assert: (result at: 'isError').
	self
		assert: ((result at: 'content') first at: 'text')
		equals: 'Missing required argument: text'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testNotificationReturnsNil [
	| response |
	response := processor processRawRequest:
		(NeoJSONWriter toString: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'method' put: 'notifications/initialized';
			at: 'params' put: Dictionary new;
			yourself)).
	self assert: response isNil
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testParseErrorReturns32700 [
	| response error |
	response := processor processRawRequest: 'this is not json at all'.
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32700
]

{ #category : 'tests - ping' }
MCPRequestProcessorTest >> testPingAnswersEmptyResult [

	| response result |
	response := processor processRawRequest: (self request: 'ping' id: 7 params: Dictionary new).
	result := self parse: response.
	self assert: (result at: 'id') equals: 7.
	self deny: (result includesKey: 'error').
	self assert: (result at: 'result') isEmpty
]

{ #category : 'tests - prompts' }
MCPRequestProcessorTest >> testPromptArgumentsAreDeclaredAndSubstituted [

	"Every argument a prompt declares must appear in its template, and an argument left out
	 must leave a readable text rather than a hole."

	| prompts |
	prompts := (self resultOf: 'prompts/list' params: Dictionary new) at: 'prompts'.
	prompts do: [ :each |
		| content template |
		content := ((self resultOf: 'prompts/get' params: (Dictionary new
			at: 'name' put: (each at: 'name');
			yourself)) at: 'messages') first at: 'content'.
		self deny: ((content at: 'text') includesSubstring: '{').
		template := (MCPRequestProcessor promptTemplates at: (each at: 'name')) at: 'template'.
		(each at: 'arguments') do: [ :argument |
			self assert: (template includesSubstring: '{' , (argument at: 'name') , '}') ] ]
]

{ #category : 'tests - prompts' }
MCPRequestProcessorTest >> testPromptsGetAnswersUserMessage [

	| result message |
	result := self resultOf: 'prompts/get' params: (Dictionary new
		at: 'name' put: 'red_green_refactor';
		at: 'arguments' put: (Dictionary new
			at: 'subject' put: 'MCPLogEntry';
			yourself);
		yourself).
	self assert: (result includesKey: 'description').
	message := (result at: 'messages') first.
	self assert: (message at: 'role') equals: 'user'.
	self assert: ((message at: 'content') at: 'type') equals: 'text'.
	self assert: (((message at: 'content') at: 'text') includesSubstring: 'MCPLogEntry').
	self assert: (((message at: 'content') at: 'text') includesSubstring: 'sampleInstance')
]

{ #category : 'tests - prompts' }
MCPRequestProcessorTest >> testPromptsGetOfUnknownNameIsError [

	| response error |
	response := processor processRawRequest: (self request: 'prompts/get' id: 9 params: (Dictionary new
		at: 'name' put: 'no_such_prompt';
		yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32602.
	self assert: ((error at: 'message') includesSubstring: 'no_such_prompt')
]

{ #category : 'tests - prompts' }
MCPRequestProcessorTest >> testPromptsListCarriesTheCycle [

	| prompts names |
	prompts := (self resultOf: 'prompts/list' params: Dictionary new) at: 'prompts'.
	names := prompts collect: [ :each | each at: 'name' ].
	self assert: (names includes: 'red_green_refactor').
	self assert: (names includes: 'bug_workflow').
	self assert: (names includes: 'design_review').
	self assert: (prompts allSatisfy: [ :each |
		(each includesKey: 'title') and: [ each includesKey: 'description' ] ])
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourceTemplatesCarryClassesAndPackages [

	| templates uris |
	templates := (self resultOf: 'resources/templates/list' params: Dictionary new)
		at: 'resourceTemplates'.
	uris := templates collect: [ :each | each at: 'uriTemplate' ].
	self assert: (uris includes: 'pharo://class/{className}').
	self assert: (uris includes: 'pharo://package/{packageName}').
	self assert: (templates allSatisfy: [ :each |
		(each includesKey: 'name') and: [ each includesKey: 'description' ] ])
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourcesListCarriesEveryPackage [

	"Packages are listed, classes are not: the image holds some fifteen thousand classes, so
	 they are reachable through the class template instead."

	| resources uris |
	resources := (self resultOf: 'resources/list' params: Dictionary new) at: 'resources'.
	uris := resources collect: [ :each | each at: 'uri' ].
	self assert: (uris includes: 'pharo://package/PharoMCP').
	self assert: resources size equals: Smalltalk packageOrganizer packageNames size.
	self assert: (resources allSatisfy: [ :each |
		(each at: 'uri') beginsWith: 'pharo://package/' ])
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourcesReadAnswersClassSource [

	| content |
	content := ((self resultOf: 'resources/read' params: (Dictionary new
		at: 'uri' put: 'pharo://class/MCPTool';
		yourself)) at: 'contents') first.
	self assert: (content at: 'uri') equals: 'pharo://class/MCPTool'.
	self assert: (content at: 'mimeType') equals: MCPRequestProcessor sourceMimeType.
	self assert: ((content at: 'text') includesSubstring: MCPTool definitionString).
	self assert: ((content at: 'text') includesSubstring: (MCPTool comment first: 20)).
	self assert: ((content at: 'text') includesSubstring: (MCPTool >> #asDictionary) sourceCode)
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourcesReadAnswersPackageClassNames [

	| content |
	content := ((self resultOf: 'resources/read' params: (Dictionary new
		at: 'uri' put: 'pharo://package/PharoMCP-Examples';
		yourself)) at: 'contents') first.
	self assert: (content at: 'uri') equals: 'pharo://package/PharoMCP-Examples'.
	(Smalltalk packageOrganizer packageNamed: 'PharoMCP-Examples') classes do: [ :each |
		self assert: ((content at: 'text') includesSubstring: each name) ]
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourcesReadOfUnknownSchemeIsError [

	| response error |
	response := processor processRawRequest: (self request: 'resources/read' id: 9 params: (Dictionary new
		at: 'uri' put: 'http://example.org/thing';
		yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: MCPRequestProcessor resourceNotFoundCode
]

{ #category : 'tests - resources' }
MCPRequestProcessorTest >> testResourcesReadOfUnknownUriIsError [

	| response error |
	response := processor processRawRequest: (self request: 'resources/read' id: 9 params: (Dictionary new
		at: 'uri' put: 'pharo://class/NoSuchClassHere';
		yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: MCPRequestProcessor resourceNotFoundCode.
	self assert: ((error at: 'message') includesSubstring: 'NoSuchClassHere')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testResponseIsValidJson [

	| response |
	response := processor processRawRequest:
		            (self request: 'tools/list' id: 1 params: Dictionary new).
	self assert: response isString.
	NeoJSONReader fromString: response
]

{ #category : 'tests - initialize' }
MCPRequestProcessorTest >> testServerInfoCarriesNameAndVersion [

	| serverInfo |
	serverInfo := (self initializeResultWithVersion: '2025-11-25') at: 'serverInfo'.
	self assert: (serverInfo at: 'name') equals: MCPRequestProcessor serverName.
	self assert: (serverInfo at: 'version') equals: MCPRequestProcessor serverVersion
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testShortResultIsNotTruncated [

	| response text |
	processor registerTool: (MCPTool
		name: 'short'
		description: 'Answers a short string'
		schema: Dictionary new
		handler: [ :args | 'brief' ]).
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'short';
		at: 'arguments' put: Dictionary new;
		yourself)).
	text := (((self parse: response) at: 'result') at: 'content') first at: 'text'.
	self assert: text equals: 'brief'
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testStructuredResultCarriesBothContentAndData [

	| result content |
	processor registerTool: ((MCPTool
		name: 'counted'
		description: 'Answers a dictionary'
		schema: Dictionary new
		handler: [ :args | Dictionary new at: 'count' put: 3; yourself ])
			outputSchema: (Dictionary new at: 'type' put: 'object'; yourself);
			yourself).
	result := (self parse: (processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'counted';
		at: 'arguments' put: Dictionary new;
		yourself)))) at: 'result'.
	self assert: ((result at: 'structuredContent') at: 'count') equals: 3.
	content := (result at: 'content') first at: 'text'.
	self assert: (content includesSubstring: '"count"').
	self deny: (result at: 'isError')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolCanBeRegisteredAfterInit [
	| newTool response tools toolNames |
	newTool := MCPTool
		name: 'late_tool'
		description: 'Added after init'
		schema: Dictionary new
		handler: [ :args | 'ok' ].
	processor registerTool: newTool.
	response := processor processRawRequest:
		(self request: 'tools/list' id: 1 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	toolNames := tools collect: [ :t | t at: 'name' ].
	self assert: (toolNames includes: 'late_tool')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolErrorSetsIsError [
	| errorTool response result |
	errorTool := MCPTool
		name: 'exploder'
		description: 'Always fails'
		schema: Dictionary new
		handler: [ :args | Error signal: 'boom' ].
	processor registerTool: errorTool.
	response := processor processRawRequest:
		(self request: 'tools/call' id: 7 params: (Dictionary new
			at: 'name' put: 'exploder';
			at: 'arguments' put: Dictionary new;
			yourself)).
	result := (self parse: response) at: 'result'.
	self assert: (result at: 'isError').
	self assert: (((result at: 'content') first at: 'text') includesSubstring: 'boom')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallIsErrorFalseOnSuccess [
	| response result |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 3 params: (Dictionary new
			at: 'name' put: 'echo';
			at: 'arguments' put: (Dictionary new at: 'text' put: 'hi'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	self deny: (result at: 'isError')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallReturnsTextContent [
	| response result content |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 3 params: (Dictionary new
			at: 'name' put: 'echo';
			at: 'arguments' put: (Dictionary new at: 'text' put: 'hello world'; yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	content := result at: 'content'.
	self assert: content isArray.
	self assert: content size equals: 1.
	self assert: ((content first) at: 'type') equals: 'text'.
	self assert: ((content first) at: 'text') equals: 'hello world'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsCallWithArithmeticTool [
	| response result content |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 4 params: (Dictionary new
			at: 'name' put: 'add';
			at: 'arguments' put: (Dictionary new
				at: 'a' put: 10;
				at: 'b' put: 32;
				yourself);
			yourself)).
	result := (self parse: response) at: 'result'.
	content := (result at: 'content') first.
	self assert: (content at: 'text') equals: '42'
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsListReturnsAllRegisteredTools [
	| response tools |
	response := processor processRawRequest:
		(self request: 'tools/list' id: 2 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	self assert: tools size equals: 2
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testToolsListToolHasRequiredFields [
	| response tools firstTool |
	response := processor processRawRequest:
		(self request: 'tools/list' id: 2 params: Dictionary new).
	tools := ((self parse: response) at: 'result') at: 'tools'.
	firstTool := tools detect: [ :t | (t at: 'name') = 'echo' ].
	self assert: (firstTool includesKey: 'name').
	self assert: (firstTool includesKey: 'description').
	self assert: (firstTool includesKey: 'inputSchema')
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testUnknownMethodReturnsError32601 [
	| response error |
	response := processor processRawRequest:
		(self request: 'nonexistent/method' id: 5 params: Dictionary new).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32601
]

{ #category : 'tests - tools/call' }
MCPRequestProcessorTest >> testUnknownToolIsProtocolError [

	| response error |
	response := processor processRawRequest: (self request: 'tools/call' id: 1 params: (Dictionary new
		at: 'name' put: 'no_such_tool';
		at: 'arguments' put: Dictionary new;
		yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32602
]

{ #category : 'tests' }
MCPRequestProcessorTest >> testUnknownToolReturnsError32602 [
	| response error |
	response := processor processRawRequest:
		(self request: 'tools/call' id: 6 params: (Dictionary new
			at: 'name' put: 'no_such_tool';
			at: 'arguments' put: Dictionary new;
			yourself)).
	error := (self parse: response) at: 'error'.
	self assert: (error at: 'code') equals: -32602
]
