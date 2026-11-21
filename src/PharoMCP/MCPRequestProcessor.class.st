"
JSON-RPC 2.0 dispatcher for the MCP protocol.

Parses raw JSON strings, routes method calls to handlers, and manages a registry of MCPTool instances (keyed by name). Created and owned by MCPServer.

Supported methods:
- initialize       returns protocol version and server capabilities
- tools/list       returns all registered tool descriptors
- tools/call       invokes a named tool with arguments

Notifications (requests without an id) return nil — no response is sent, per JSON-RPC 2.0 spec. All errors are returned as JSON-RPC error response objects with standard codes (-32700 parse, -32600 invalid, -32601 not found, -32602 invalid params, -32603 internal).
"
Class {
	#name : 'MCPRequestProcessor',
	#superclass : 'Object',
	#instVars : [
		'tools'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'prompts' }
MCPRequestProcessor class >> bugWorkflowTemplate [

	^ (String cr , String cr) join: #(
		'A bug is reported in this Pharo image: {symptom}.'
		'Reproduce it first. Write the test that fails because of the bug, compile it with compile_method and see it fail with run_tests. Never write the fix first: a fix with no failing test behind it cannot be shown to fix anything.'
		'Find the cause before changing a method. Read the code with method_source, and check who depends on it with find_senders and find_implementors; a method with senders you have not read is a method you cannot safely change.'
		'Then write the smallest change that turns the test green, re-run the whole suite, and run run_critics on the class you changed. An empty on:do: handler is always a bug, never an acceptable fix.' )
]

{ #category : 'constants' }
MCPRequestProcessor class >> capabilities [

	"What the initialize result declares. Resources and prompts carry no subscription and
	 no change notification, because the server has no stream to send one on."

	^ Dictionary new
		at: 'tools' put: Dictionary new;
		at: 'completions' put: Dictionary new;
		at: 'resources' put: Dictionary new;
		at: 'prompts' put: Dictionary new;
		yourself
]

{ #category : 'constants' }
MCPRequestProcessor class >> classUriPrefix [

	^ 'pharo://class/'
]

{ #category : 'constants' }
MCPRequestProcessor class >> completionSources [

	"Each key is the prefix of a pharo:// resource URI, and each value answers the whole
	 set of names that kind of resource can carry. The sets are built on demand, because
	 the selector table of this image holds some ninety thousand symbols and holding a
	 copy of it would go stale on the next compile."

	^ Dictionary new
		at: self classUriPrefix put: [ Smalltalk globals keys select: [ :each |
			(Smalltalk globals at: each) isBehavior ] ];
		at: self packageUriPrefix put: [ Smalltalk packageOrganizer packageNames ];
		at: self selectorUriPrefix put: [ Symbol selectorTable ];
		yourself
]

{ #category : 'prompts' }
MCPRequestProcessor class >> designReviewTemplate [

	^ (String cr , String cr) join: #(
		'Review the design of {subject} in this Pharo image. Change nothing until the plan is agreed.'
		'Diagnose, naming the class or method for every point: methods too long or mixing levels of abstraction; duplication within a class or between sibling classes, which is a candidate to pull up; type tests that polymorphism would replace; feature envy, a method working mostly on another object''s data; primitive obsession, a domain concept carried as a string, a number or a dictionary; chains of message sends; and names that describe the implementation rather than the intention. Run run_critics on the same classes and fold in what is relevant.'
		'Prioritise by gain against risk, and name the refactoring for each point: Extract Method, Move Method, Replace Conditional with Polymorphism, Pull Up Method.'
		'Introduce no abstraction, no layer of indirection and no design pattern for a hypothetical need. A proposal that adds classes or methods must say what it simplifies today.'
		'Present the plan and wait for validation. Then execute one refactoring at a time, re-running the suite after each, and change no test during this phase. If a refactoring forces a test to change, stop and report it.' )
]

{ #category : 'constants' }
MCPRequestProcessor class >> handlerSelectors [

	"Every handler takes the params and the id, so the dispatch needs no case analysis;
	 ping ignores its params."

	^ Dictionary new
		at: 'initialize' put: #handleInitialize:id:;
		at: 'ping' put: #handlePing:id:;
		at: 'tools/list' put: #handleToolsList:id:;
		at: 'tools/call' put: #handleToolsCall:id:;
		at: 'completion/complete' put: #handleCompletionComplete:id:;
		at: 'resources/list' put: #handleResourcesList:id:;
		at: 'resources/templates/list' put: #handleResourcesTemplatesList:id:;
		at: 'resources/read' put: #handleResourcesRead:id:;
		at: 'prompts/list' put: #handlePromptsList:id:;
		at: 'prompts/get' put: #handlePromptsGet:id:;
		yourself
]

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> instructions [

	"Sent once, in the initialize result. A client reads it before it calls a tool, so it
	 states the rules of this image that a caller cannot discover from a tool schema."

	^ (String cr , String cr) join: #(
		'This server drives a live Pharo image. The image is the source of truth: change code through compile_method, class_create, delete_method and the other tools, never by writing a .class.st file.'
		'Pharo source uses CR line endings. A multi-line method body sent to compile_method must separate its lines with CR, never LF; an escape sequence is compiled as its own characters.'
		'Write the failing test before the code, run it with run_tests, and run run_critics on every class you change before you call the work done.'
		'evaluate_pharo answers the printString of the last expression. A result longer than the server''s maximum is truncated, and the note states how many characters it held.' )
]

{ #category : 'protocol versions' }
MCPRequestProcessor class >> latestProtocolVersion [

	^ self supportedProtocolVersions first
]

{ #category : 'constants' }
MCPRequestProcessor class >> maximumCompletionValues [

	"The specification caps a completion response at 100 values."

	^ 100
]

{ #category : 'accessing' }
MCPRequestProcessor class >> maximumResultSize [

	"Characters of a tool result the server sends before cutting it. A client pays for every
	 one of them in its context window, and a tool asked for too much is better corrected than
	 answered in full."

	^ 10000
]

{ #category : 'resources' }
MCPRequestProcessor class >> methodSourcesOf: aBehavior [

	^ aBehavior selectors asSortedCollection asArray collect: [ :each |
		aBehavior name , ' >> ' , each , String cr , (aBehavior >> each) sourceCode ]
]

{ #category : 'constants' }
MCPRequestProcessor class >> packageUriPrefix [

	^ 'pharo://package/'
]

{ #category : 'prompts' }
MCPRequestProcessor class >> promptTemplates [

	"The workflows this image is developed by. Each argument''s placeholder is what the
	 template reads when a client leaves the argument out, so a prompt is readable even
	 when it is asked for with no arguments at all."

	^ Dictionary new
		at: 'red_green_refactor' put: (Dictionary new
			at: 'title' put: 'Red, green, refactor, example, view';
			at: 'description' put: 'The five steps every unit of work in this image goes through.';
			at: 'template' put: self redGreenRefactorTemplate;
			at: 'arguments' put: { Dictionary new
				at: 'name' put: 'subject';
				at: 'description' put: 'Class, method or feature the unit of work is about.';
				at: 'placeholder' put: 'the class you are asked to change';
				yourself };
			yourself);
		at: 'bug_workflow' put: (Dictionary new
			at: 'title' put: 'Reproduce before you fix';
			at: 'description' put: 'How a defect is handled here: the failing test comes first.';
			at: 'template' put: self bugWorkflowTemplate;
			at: 'arguments' put: { Dictionary new
				at: 'name' put: 'symptom';
				at: 'description' put: 'What goes wrong, as a reader of the report would say it.';
				at: 'placeholder' put: 'the symptom you were given';
				yourself };
			yourself);
		at: 'design_review' put: (Dictionary new
			at: 'title' put: 'Design review of finished work';
			at: 'description' put: 'The review a feature gets once its tests are green.';
			at: 'template' put: self designReviewTemplate;
			at: 'arguments' put: { Dictionary new
				at: 'name' put: 'subject';
				at: 'description' put: 'Class or package whose design is under review.';
				at: 'placeholder' put: 'the code the finished feature touched';
				yourself };
			yourself);
		yourself
]

{ #category : 'prompts' }
MCPRequestProcessor class >> redGreenRefactorTemplate [

	^ (String cr , String cr) join: #(
		'Work on {subject} in this Pharo image through the MCP tools, one unit at a time, in five steps.'
		'1. Red. Write the failing test first with compile_method on the test class, then run it with run_tests and read the failure. A test states a fact, fails when that fact stops holding, and covers the degenerate cases too.'
		'2. Green. Write the smallest code that passes. Nothing more.'
		'3. Refactor. With the suite green, remove the duplication the green step introduced and check the names say what the code means. No new abstraction until the same duplication has appeared three times.'
		'4. Example. Add or extend a class-side unary method tagged <sampleInstance> on the matching <Subject>Examples class. It rebuilds the object on every call and asserts nothing, so a reader runs it with one click. An example that opens a window is named open...'
		'5. View. Add a custom inspector view: a keyword method taking the presenter builder as its only argument, tagged <inspectorPresentationOrder:title:>, building through the builder. It never mutates the inspected object, and it asks the real rule rather than restating it.'
		'Then run run_critics on every class you changed. The unit is not done until all five artefacts exist and critics are clean on what changed.' )
]

{ #category : 'constants' }
MCPRequestProcessor class >> resourceNotFoundCode [

	"The code the specification reserves for a resource URI that answers nothing."

	^ -32002
]

{ #category : 'resources' }
MCPRequestProcessor class >> resourceSources [

	"One table behind resources/templates/list and resources/read, so a kind of resource
	 cannot be offered as a template and then answer nothing when it is read."

	^ Dictionary new
		at: self classUriPrefix put: (Dictionary new
			at: 'parameter' put: 'className';
			at: 'name' put: 'Pharo class';
			at: 'description' put: 'Definition, class comment and full method source of one class.';
			at: 'reader' put: [ :className | self sourceOfClassNamed: className ];
			yourself);
		at: self packageUriPrefix put: (Dictionary new
			at: 'parameter' put: 'packageName';
			at: 'name' put: 'Pharo package';
			at: 'description' put: 'Class names, with their comments, of one package.';
			at: 'reader' put: [ :packageName | self sourceOfPackageNamed: packageName ];
			yourself);
		yourself
]

{ #category : 'constants' }
MCPRequestProcessor class >> samplePrefixSize [

	"Letters of a sampled name the Completion inspector view uses as a prefix."

	^ 3
]

{ #category : 'constants' }
MCPRequestProcessor class >> selectorUriPrefix [

	"Selectors are completed but not read: a selector alone names no source."

	^ 'pharo://selector/'
]

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> serverName [

	"The name a client shows for this server, and the name the test reads rather than
	 repeating the literal."

	^ 'PharoMCP'
]

{ #category : 'accessing - server info' }
MCPRequestProcessor class >> serverVersion [

	"Neither BaselineOfPharoMCP nor a Pharo package carries a version number, so this method
	 is the one place the server''s version is written. Raise it when the protocol surface or
	 the tool set changes, not on every commit."

	^ '1.1.0'
]

{ #category : 'constants' }
MCPRequestProcessor class >> sourceMimeType [

	^ 'text/x-smalltalk'
]

{ #category : 'resources' }
MCPRequestProcessor class >> sourceOfClassNamed: aString [

	"nil, rather than an empty text, when the image holds no such class: the caller turns
	 that into the resource-not-found error the specification asks for."

	| class |
	class := Smalltalk globals at: aString asSymbol ifAbsent: [ ^ nil ].
	class isBehavior ifFalse: [ ^ nil ].
	^ String cr join: (
		(OrderedCollection new
			add: class definitionString;
			add: '"' , (class comment ifNil: [ '' ]) , '"';
			yourself) ,
		(self methodSourcesOf: class) ,
		(self methodSourcesOf: class classSide))
]

{ #category : 'resources' }
MCPRequestProcessor class >> sourceOfPackageNamed: aString [

	| package |
	package := Smalltalk packageOrganizer packageNamed: aString ifAbsent: [ ^ nil ].
	^ String cr join: ((package classes asSortedCollection: [ :a :b | a name <= b name ]) asArray
		collect: [ :each |
			each name , String cr , '"' , (each comment ifNil: [ '' ]) , '"' ])
]

{ #category : 'protocol versions' }
MCPRequestProcessor class >> supportedProtocolVersions [

	"Newest first: the first entry is what a client that asks for nothing, or for a revision this
	 server does not know, is answered. 2024-11-05 stays in the list because clients still ask
	 for it and the specification requires the server to echo a revision it supports."

	^ #( '2025-11-25' '2025-06-18' '2025-03-26' '2024-11-05' )
]

{ #category : 'completion' }
MCPRequestProcessor >> completionNamesFor: aUri startingWith: aPrefix [

	| source |
	source := self class completionSources associations
		detect: [ :each | aUri beginsWith: each key ]
		ifNone: [ ^ #() ].
	^ ((source value value select: [ :candidate | candidate beginsWith: aPrefix ])
		collect: [ :candidate | candidate asString ]) asSortedCollection asArray
]

{ #category : 'completion' }
MCPRequestProcessor >> completionReportFor: aUri [

	"What one completion source answers right now: how many names it holds, the prefix
	 sampled from the first of them, and what the real completion method makes of it."

	| names prefix result |
	names := self completionNamesFor: aUri startingWith: ''.
	prefix := names
		ifEmpty: [ '' ]
		ifNotEmpty: [ names first first: (self class samplePrefixSize min: names first size) ].
	result := self completionResultFor: aUri startingWith: prefix.
	^ Dictionary new
		at: 'uri' put: aUri;
		at: 'names' put: names size;
		at: 'prefix' put: prefix;
		at: 'total' put: (result at: 'total');
		at: 'answered' put: (result at: 'values') size;
		at: 'hasMore' put: (result at: 'hasMore');
		yourself
]

{ #category : 'completion' }
MCPRequestProcessor >> completionResultFor: aUri startingWith: aPrefix [

	| names limit |
	names := self completionNamesFor: aUri startingWith: aPrefix.
	limit := self class maximumCompletionValues.
	^ Dictionary new
		at: 'values' put: (names size <= limit
			ifTrue: [ names ]
			ifFalse: [ names first: limit ]);
		at: 'total' put: names size;
		at: 'hasMore' put: names size > limit;
		yourself
]

{ #category : 'processing' }
MCPRequestProcessor >> dispatchRequest: request [

	| method id params selector |
	id := request at: 'id' ifAbsent: [ nil ].
	method := request at: 'method' ifAbsent: [
		^ self errorResponseWithId: id code: -32600 message: 'Invalid Request' ].
	params := request at: 'params' ifAbsent: [ Dictionary new ].
	"Notifications have no id — no response per JSON-RPC 2.0"
	(id isNil and: [ method beginsWith: 'notifications/' ]) ifTrue: [ ^ nil ].
	selector := self class handlerSelectors at: method ifAbsent: [
		^ self errorResponseWithId: id code: -32601 message: 'Method not found: ' , method ].
	^ self perform: selector with: params with: id
]

{ #category : 'response building' }
MCPRequestProcessor >> errorResponseWithId: id code: code message: msg [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'error' put: (Dictionary new
			at: 'code' put: code;
			at: 'message' put: msg;
			yourself);
		yourself)
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleCompletionComplete: params id: id [

	| reference uri argument prefix |
	reference := params at: 'ref' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: ref' ].
	uri := reference at: 'uri' ifAbsent: [ reference at: 'name' ifAbsent: [ '' ] ].
	argument := params at: 'argument' ifAbsent: [ Dictionary new ].
	prefix := argument at: 'value' ifAbsent: [ '' ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'completion' put: (self completionResultFor: uri startingWith: prefix);
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleInitialize: params id: id [

	^ self
		successResponseWithResult: (Dictionary new
			at: 'protocolVersion' put: (self negotiatedProtocolVersionFor: params);
			at: 'capabilities' put: self class capabilities;
			at: 'serverInfo' put: (Dictionary new
				at: 'name' put: self class serverName;
				at: 'version' put: self class serverVersion;
				yourself);
			at: 'instructions' put: self class instructions;
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handlePing: params id: id [

	"A ping carries no parameters; the argument is here so every handler in
	 handlerSelectors has the same shape."

	^ self successResponseWithResult: Dictionary new id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handlePromptsGet: params id: id [

	| name template arguments |
	name := params at: 'name' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: name' ].
	template := self class promptTemplates at: name ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Unknown prompt: ' , name ].
	arguments := params at: 'arguments' ifAbsent: [ Dictionary new ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'description' put: (template at: 'description');
			at: 'messages' put: { Dictionary new
				at: 'role' put: 'user';
				at: 'content' put: (Dictionary new
					at: 'type' put: 'text';
					at: 'text' put: (self promptTextOf: template with: arguments);
					yourself);
				yourself };
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handlePromptsList: params id: id [

	| names |
	names := self class promptTemplates keys asSortedCollection asArray.
	^ self
		successResponseWithResult: (Dictionary new
			at: 'prompts' put: (names collect: [ :each |
				| template |
				template := self class promptTemplates at: each.
				Dictionary new
					at: 'name' put: each;
					at: 'title' put: (template at: 'title');
					at: 'description' put: (template at: 'description');
					at: 'arguments' put: ((template at: 'arguments') collect: [ :argument |
						Dictionary new
							at: 'name' put: (argument at: 'name');
							at: 'description' put: (argument at: 'description');
							at: 'required' put: false;
							yourself ]);
					yourself ]);
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleResourcesList: params id: id [

	"Packages are the listed resources; the image holds some fifteen thousand classes, so a
	 class is reached through its template instead of being listed one by one."

	^ self
		successResponseWithResult: (Dictionary new
			at: 'resources' put: (Smalltalk packageOrganizer packageNames asSortedCollection asArray
				collect: [ :each |
					Dictionary new
						at: 'uri' put: self class packageUriPrefix , each;
						at: 'name' put: each;
						at: 'mimeType' put: self class sourceMimeType;
						yourself ]);
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleResourcesRead: params id: id [

	| uri text |
	uri := params at: 'uri' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: uri' ].
	text := self resourceTextFor: uri.
	text ifNil: [
		^ self
			errorResponseWithId: id
			code: self class resourceNotFoundCode
			message: 'Resource not found: ' , uri ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'contents' put: { Dictionary new
				at: 'uri' put: uri;
				at: 'mimeType' put: self class sourceMimeType;
				at: 'text' put: text;
				yourself };
			yourself)
		id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleResourcesTemplatesList: params id: id [

	| templates |
	templates := self class resourceSources associations asSortedCollection: [ :a :b | a key <= b key ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'resourceTemplates' put: (templates asArray collect: [ :each |
				Dictionary new
					at: 'uriTemplate' put: each key , '{' , (each value at: 'parameter') , '}';
					at: 'name' put: (each value at: 'name');
					at: 'description' put: (each value at: 'description');
					at: 'mimeType' put: self class sourceMimeType;
					yourself ]);
			yourself)
		id: id
]

{ #category : 'handling' }
MCPRequestProcessor >> handleToolsCall: params id: id [

	| toolName args tool missing |
	toolName := params at: 'name' ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Missing parameter: name' ].
	args := params at: 'arguments' ifAbsent: [ Dictionary new ].
	tool := tools at: toolName ifAbsent: [
		^ self errorResponseWithId: id code: -32602 message: 'Tool not found: ' , toolName ].
	missing := tool missingRequiredArgumentsIn: args.
	missing ifNotEmpty: [
		^ self toolErrorResult: (self missingArgumentsMessage: missing) id: id ].
	^ self resultOfCalling: tool with: args id: id
]

{ #category : 'handlers' }
MCPRequestProcessor >> handleToolsList: params id: id [
	| toolList |
	toolList := tools values collect: [ :t | t asDictionary ].
	^ self
		successResponseWithResult: (Dictionary new
			at: 'tools' put: toolList asArray;
			yourself)
		id: id
]

{ #category : 'initialization' }
MCPRequestProcessor >> initialize [

	super initialize.
	tools := Dictionary new
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionCompletion: aBuilder [

	<inspectorPresentationOrder: 3 title: 'Completion'>

	"Each row asks the real method, with a prefix sampled from the source's own names, so a
	 source that stops answering shows zero here instead of a prefix that never matched."

	^ aBuilder newTable
		items: (self class completionSources keys asSortedCollection asArray collect: [ :uri |
			self completionReportFor: uri ]);
		addColumn: (SpStringTableColumn title: 'Resource' evaluated: [ :each | each at: 'uri' ]);
		addColumn: (SpStringTableColumn title: 'Names' evaluated: [ :each |
			(each at: 'names') printString ]);
		addColumn: (SpStringTableColumn title: 'Prefix' evaluated: [ :each | each at: 'prefix' ]);
		addColumn: (SpStringTableColumn title: 'Matching' evaluated: [ :each |
			(each at: 'total') printString ]);
		addColumn: (SpStringTableColumn title: 'Answered' evaluated: [ :each |
			(each at: 'answered') printString ]);
		addColumn: (SpStringTableColumn title: 'More' evaluated: [ :each |
			(each at: 'hasMore') printString ]);
		yourself
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionPrompts: aBuilder [

	<inspectorPresentationOrder: 5 title: 'Prompts'>

	"Each row renders the prompt with no arguments at all, which is the case a brace would
	 survive, and reports whether one did."

	^ aBuilder newTable
		items: (self class promptTemplates keys asSortedCollection asArray collect: [ :name |
			self promptReportFor: name ]);
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :each | each at: 'name' ]);
		addColumn: (SpStringTableColumn title: 'Title' evaluated: [ :each | each at: 'title' ]);
		addColumn: (SpStringTableColumn title: 'Arguments' evaluated: [ :each | each at: 'arguments' ]);
		addColumn: (SpStringTableColumn title: 'Characters' evaluated: [ :each |
			(each at: 'size') printString ]);
		addColumn: (SpStringTableColumn title: 'Unfilled brace' evaluated: [ :each |
			(each at: 'unfilled') printString ]);
		yourself
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionProtocol: aBuilder [

	<inspectorPresentationOrder: 2 title: 'Protocol'>

	| supported older unknown |
	supported := self class supportedProtocolVersions.
	older := supported last.
	unknown := 'no-such-revision'.
	^ (StSimpleInspectorBuilder on: aBuilder)
		key: 'Supported' value: (', ' join: supported);
		key: 'Latest' value: self class latestProtocolVersion;
		key: 'Client asks ' , older value: (self negotiatedProtocolVersionFor: (Dictionary with: 'protocolVersion' -> older));
		key: 'Client asks ' , unknown value: (self negotiatedProtocolVersionFor: (Dictionary with: 'protocolVersion' -> unknown));
		key: 'Client asks nothing' value: (self negotiatedProtocolVersionFor: Dictionary new);
		table
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionResources: aBuilder [

	<inspectorPresentationOrder: 4 title: 'Resources'>

	"Each row reads the resource the template would build for a name taken from the source
	 itself, so a template that is offered but unreadable shows an empty size here."

	^ aBuilder newTable
		items: (self class resourceSources keys asSortedCollection asArray collect: [ :prefix |
			self resourceReportFor: prefix ]);
		addColumn: (SpStringTableColumn title: 'Template' evaluated: [ :each | each at: 'template' ]);
		addColumn: (SpStringTableColumn title: 'Sample' evaluated: [ :each | each at: 'sample' ]);
		addColumn: (SpStringTableColumn title: 'Characters read' evaluated: [ :each |
			(each at: 'size') printString ]);
		yourself
]

{ #category : 'inspector' }
MCPRequestProcessor >> inspectionTools: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Tools'>
	| sorted |
	sorted := tools values asSortedCollection: [ :a :b | a name < b name ].
	^ aBuilder newTable
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :t | t name ]);
		addColumn: (SpStringTableColumn title: 'Description' evaluated: [ :t | t description truncateWithElipsisTo: 80 ]);
		items: sorted;
		yourself
]

{ #category : 'private' }
MCPRequestProcessor >> missingArgumentsMessage: aCollection [

	^ (aCollection size = 1
		ifTrue: [ 'Missing required argument: ' ]
		ifFalse: [ 'Missing required arguments: ' ]) , (', ' join: aCollection)
]

{ #category : 'private' }
MCPRequestProcessor >> negotiatedProtocolVersionFor: params [

	| requested |
	requested := params at: 'protocolVersion' ifAbsent: [ ^ self class latestProtocolVersion ].
	^ (self class supportedProtocolVersions includes: requested)
		ifTrue: [ requested ]
		ifFalse: [ self class latestProtocolVersion ]
]

{ #category : 'processing' }
MCPRequestProcessor >> processRawRequest: jsonString [
	| request |
	request := [ NeoJSONReader fromString: jsonString ]
		on: Error
		do: [ :e |
			^ self
				errorResponseWithId: nil
				code: -32700
				message: 'Parse error' ].
	(request isDictionary) ifFalse: [
		^ self errorResponseWithId: nil code: -32600 message: 'Invalid Request' ].
	^ self dispatchRequest: request
]

{ #category : 'prompts' }
MCPRequestProcessor >> promptReportFor: aName [

	"What one prompt answers when it is asked for with no arguments, read through the real
	 substitution method."

	| template text |
	template := self class promptTemplates at: aName.
	text := self promptTextOf: template with: Dictionary new.
	^ Dictionary new
		at: 'name' put: aName;
		at: 'title' put: (template at: 'title');
		at: 'arguments' put: (', ' join: ((template at: 'arguments') collect: [ :each |
			each at: 'name' ]));
		at: 'size' put: text size;
		at: 'unfilled' put: (text includesSubstring: '{');
		yourself
]

{ #category : 'prompts' }
MCPRequestProcessor >> promptTextOf: aTemplate with: anArgumentDictionary [

	"An argument the client leaves out reads as its placeholder, so the text never shows a
	 brace to the model that is asked to follow it."

	| text |
	text := aTemplate at: 'template'.
	(aTemplate at: 'arguments') do: [ :argument |
		| value |
		value := anArgumentDictionary
			at: (argument at: 'name')
			ifAbsent: [ argument at: 'placeholder' ].
		text := text copyReplaceAll: '{' , (argument at: 'name') , '}' with: value ].
	^ text
]

{ #category : 'tool management' }
MCPRequestProcessor >> registerTool: aTool [
	tools at: aTool name put: aTool
]

{ #category : 'resources' }
MCPRequestProcessor >> resourceReportFor: aPrefix [

	"What one resource kind answers right now, read through the real method with a name
	 sampled from the matching completion source."

	| source names sample text |
	source := self class resourceSources at: aPrefix.
	names := self completionNamesFor: aPrefix startingWith: ''.
	sample := names ifEmpty: [ '' ] ifNotEmpty: [ names first ].
	text := sample ifEmpty: [ '' ] ifNotEmpty: [ self resourceTextFor: aPrefix , sample ].
	^ Dictionary new
		at: 'template' put: aPrefix , '{' , (source at: 'parameter') , '}';
		at: 'sample' put: sample;
		at: 'size' put: (text ifNil: [ 0 ] ifNotNil: [ :found | found size ]);
		yourself
]

{ #category : 'resources' }
MCPRequestProcessor >> resourceTextFor: aUri [

	"nil when no source claims the URI, or when the one that does holds no such name."

	| source |
	source := self class resourceSources associations
		detect: [ :each | aUri beginsWith: each key ]
		ifNone: [ ^ nil ].
	^ (source value at: 'reader') value: (aUri allButFirst: source key size)
]

{ #category : 'handlers' }
MCPRequestProcessor >> resultOfCalling: aTool with: arguments id: id [

	| result isError |
	isError := false.
	result := [ aTool call: arguments ]
		on: Error
		do: [ :e |
			isError := true.
			"messageText is nil for errors signalled without one, and a nil would
			 break the concatenation inside this handler, which nothing catches."
			'Error: ' , (e messageText ifNil: [ e class name ]) ].
	(isError not and: [ aTool answersStructuredContent: result ]) ifTrue: [
		^ self
			toolResult: (self truncated: (NeoJSONWriter toStringPretty: result))
			structured: result
			id: id ].
	result isString ifFalse: [ result := result printString ].
	^ self toolResult: (self truncated: result) isError: isError id: id
]

{ #category : 'response building' }
MCPRequestProcessor >> successResponseWithResult: result id: id [
	^ NeoJSONWriter toString: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'result' put: result;
		yourself)
]

{ #category : 'private' }
MCPRequestProcessor >> toolErrorResult: aString id: id [

	^ self toolResult: aString isError: true id: id
]

{ #category : 'private' }
MCPRequestProcessor >> toolResult: aString isError: aBoolean id: id [

	^ self
		successResponseWithResult: (Dictionary new
			at: 'content' put: (Array with: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: aString;
				yourself));
			at: 'isError' put: aBoolean;
			yourself)
		id: id
]

{ #category : 'private' }
MCPRequestProcessor >> toolResult: aString structured: aDictionary id: id [

	"A tool with an outputSchema answers its data in structuredContent, and the specification
	 asks for the same data serialised in the text block, for a client that reads only text."

	^ self
		successResponseWithResult: (Dictionary new
			at: 'content' put: { Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: aString;
				yourself };
			at: 'structuredContent' put: aDictionary;
			at: 'isError' put: false;
			yourself)
		id: id
]

{ #category : 'accessing' }
MCPRequestProcessor >> tools [
	^ tools
]

{ #category : 'private' }
MCPRequestProcessor >> truncated: aString [

	| limit |
	limit := self class maximumResultSize.
	aString size <= limit ifTrue: [ ^ aString ].
	^ (aString first: limit) , '...(truncated, ' , aString size printString , ' characters)'
]
