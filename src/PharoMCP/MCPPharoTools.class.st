"
Factory for the built-in Pharo image introspection tools.

All methods are class-side. Registered automatically during MCPServer initialization via registerToolsWith: aProcessor. Add a new tool by implementing a new class-side factory method and including it in allTools.

Provided tools:
- evaluate_pharo      evaluate arbitrary Pharo code, returns printString of result
- list_classes        search classes by name pattern (case-insensitive, max 50)
- class_definition    return definitionString of a named class
- method_source       return source code of a named method (instance or class side)
- list_methods        list all selectors on a class (instance or class side)
"
Class {
	#name : 'MCPPharoTools',
	#superclass : 'Object',
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'registration' }
MCPPharoTools class >> allTools [
	^ (OrderedCollection new
		add: self evaluateTool; add: self listClassesTool; add: self classDefinitionTool;
		add: self methodSourceTool; add: self compileMethodTool; add: self deleteMethodTool;
		add: self renameMethodTool; add: self moveMethodTool; add: self createClassTool;
		add: self removeClassTool; add: self renameClassTool; add: self classCommentTool;
		add: self listMethodsTool; add: self searchSourceTool; add: self runTestsTool;
		add: self runCriticsTool; add: self findSendersTool; add: self findImplementorsTool;
		add: self listPackagesTool; add: self createPackageTool; add: self removePackageTool;
		add: self classHierarchyTool;
		yourself) asArray
]

{ #category : 'tools' }
MCPPharoTools class >> classCommentTool [

	^ (MCPTool
		name: 'class_comment'
		description: 'Get or set the comment (documentation) on a class. Omit the comment parameter to read; supply it to write.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
				'comment' -> (self schemaPropertyOfType: 'string' describedAs: 'New comment text. Omit to read the current comment.') }
			required: #('class_name'))
		handler: [ :args |
			(args at: 'comment' ifAbsent: [ nil ])
				ifNil: [ self getClassComment: (args at: 'class_name') ]
				ifNotNil: [ :comment | self setClassComment: comment onClass: (args at: 'class_name') ] ])
		title: 'Read or write a class comment';
		additive;
		yourself
]

{ #category : 'tools' }
MCPPharoTools class >> classDefinitionTool [

	^ (MCPTool
		name: 'class_definition'
		description: 'Get the definition of a Pharo class including its superclass, instance variables, and package.'
		schema: (self
			schemaWithProperties: { 'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Exact name of the class') }
			required: #('className'))
		handler: [ :args | (self classNamed: (args at: 'className')) definitionString ])
		title: 'Show a class definition';
		readOnly;
		yourself
]

{ #category : 'browsing' }
MCPPharoTools class >> classHierarchyOf: className [

	| cls superchain subs |
	cls := self classNamed: className.
	superchain := cls allSuperclasses reversed.
	subs := cls subclasses asSortedCollection: [ :a :b | a name < b name ].
	^ String streamContents: [ :s |
		s << 'Superclass chain:'; nextPut: Character lf.
		s << (((superchain collect: [ :c | c name ]) , (Array with: cls name)) joinUsing: ' > ').
		s nextPut: Character lf; nextPut: Character lf.
		s << 'Direct subclasses ('; print: subs size; << '):'; nextPut: Character lf.
		subs isEmpty
			ifTrue: [ s << '  (none)' ]
			ifFalse: [ subs do: [ :c | s << '  '; << c name; nextPut: Character lf ] ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> classHierarchyTool [

	^ (MCPTool
		name: 'class_hierarchy'
		description: 'Show superclass chain and direct subclasses of a class.'
		schema: (self
			schemaWithProperties: { 'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class') }
			required: #('class_name'))
		handler: [ :args | self classHierarchyOf: (args at: 'class_name') ])
		title: 'Show a class hierarchy';
		readOnly;
		yourself
]

{ #category : 'private' }
MCPPharoTools class >> classNamed: aString [

	^ self classNamed: aString as: 'class'
]

{ #category : 'private' }
MCPPharoTools class >> classNamed: aString as: aRole [

	^ self classNamed: aString as: aRole side: 'instance'
]

{ #category : 'private' }
MCPPharoTools class >> classNamed: aString as: aRole side: aSide [

	"The class, or its metaclass when the call asks for the class side, with the failure the
	 caller reads. The role names what the name stood for in the call — a class, a superclass,
	 a source class — so one lookup serves them all."
	| cls |
	cls := Smalltalk globals at: aString asSymbol ifAbsent: [
		MCPToolError signal: aRole , ' not found: ' , aString ].
	^ aSide = 'class'
		ifTrue: [ cls class ]
		ifFalse: [ cls ]
]

{ #category : 'private' }
MCPPharoTools class >> classNamed: aString side: aSide [

	^ self classNamed: aString as: 'class' side: aSide
]

{ #category : 'running' }
MCPPharoTools class >> collectCritiquesForClass: aClass [

	| critiques |
	critiques := OrderedCollection new.
	critiques addAll: (ReCriticEngine critiquesOf: aClass).
	critiques addAll: (ReCriticEngine critiquesOf: aClass class).
	aClass methodDictionary valuesDo: [ :m |
		critiques addAll: (ReCriticEngine critiquesOf: m) ].
	aClass class methodDictionary valuesDo: [ :m |
		critiques addAll: (ReCriticEngine critiquesOf: m) ].
	^ critiques
]

{ #category : 'editing' }
MCPPharoTools class >> compileMethod: source onClass: className side: side classified: protocol [

	| target normalizedSource selector |
	target := self classNamed: className side: side.
	normalizedSource := source
		copyReplaceAll: (String with: Character lf)
		with: (String with: Character cr).
	selector := [ target compile: normalizedSource classified: protocol asSymbol ]
		on: Error
		do: [ :e | MCPToolError signal: 'compilation failed: ' , e messageText ].
	^ 'Compiled: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , selector
]

{ #category : 'tools' }
MCPPharoTools class >> compileMethodTool [

	^ (MCPTool
		name: 'compile_method'
		description: 'Compile a method on a class. Returns the selector on success. Use side "class" for class-side methods. LF line endings are normalised automatically.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
				'source' -> (self schemaPropertyOfType: 'string' describedAs: 'Full method source including selector').
				'side' -> self schemaSideProperty.
				'protocol' -> (self schemaPropertyOfType: 'string' describedAs: 'Protocol name. Defaults to ''as yet unclassified''.') }
			required: #('class_name' 'source'))
		handler: [ :args |
			self
				compileMethod: (args at: 'source')
				onClass: (args at: 'class_name')
				side: (args at: 'side' ifAbsent: [ 'instance' ])
				classified: (args at: 'protocol' ifAbsent: [ 'as yet unclassified' ]) ])
		title: 'Compile a method';
		additive;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> createClass: className superclass: superclsName instanceVariables: instVarNames package: packageName [

	| supercls slots |
	(Smalltalk globals includesKey: className asSymbol) ifTrue: [
		MCPToolError signal: 'class already exists: ' , className ].
	supercls := self classNamed: superclsName as: 'superclass'.
	slots := (instVarNames ifNil: [ #() ]) collect: [ :n | n asSymbol ].
	[ (supercls << className asSymbol
		slots: slots;
		package: packageName) install ]
		on: Error
		do: [ :e | MCPToolError signal: 'class creation failed: ' , e messageText ].
	^ 'Created: ' , className
		, ' (subclass of ' , superclsName
		, ', ' , slots size printString , ' instance variable'
		, (slots size = 1 ifTrue: [ '' ] ifFalse: [ 's' ])
		, ')'
]

{ #category : 'tools' }
MCPPharoTools class >> createClassTool [

	^ (MCPTool
		name: 'class_create'
		description: 'Create a new Pharo class. Fails if the class already exists. Use compile_method to add methods after creation.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the new class').
				'superclass_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Superclass name. Defaults to Object.').
				'instance_variables' -> (Dictionary new
					at: 'type' put: 'array';
					at: 'items' put: (Dictionary new at: 'type' put: 'string'; yourself);
					at: 'description' put: 'Instance variable names. Defaults to none.';
					yourself).
				'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name, e.g. MyApp or MyApp-Core.') }
			required: #('class_name' 'package'))
		handler: [ :args |
			self
				createClass: (args at: 'class_name')
				superclass: (args at: 'superclass_name' ifAbsent: [ 'Object' ])
				instanceVariables: (args at: 'instance_variables' ifAbsent: [ #() ])
				package: (args at: 'package') ])
		title: 'Create a class';
		additive;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> createPackage: packageName [

	(Smalltalk packageOrganizer hasPackage: packageName) ifTrue: [
		MCPToolError signal: 'package already exists: ' , packageName ].
	Smalltalk packageOrganizer ensurePackage: packageName.
	^ 'Created package: ' , packageName
]

{ #category : 'tools' }
MCPPharoTools class >> createPackageTool [

	^ (MCPTool
		name: 'package_create'
		description: 'Create a new package in the image. Fails if a package with that name already exists.'
		schema: (self
			schemaWithProperties: { 'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name, e.g. MyApp or MyApp-Core') }
			required: #('package'))
		handler: [ :args | self createPackage: (args at: 'package') ])
		title: 'Create a package';
		additive;
		yourself
]

{ #category : 'tools - critics' }
MCPPharoTools class >> critiqueDictionaryFor: aCritique [

	| dictionary |
	dictionary := Dictionary new
		at: 'rule' put: aCritique rule class name;
		at: 'title' put: aCritique title;
		yourself.
	aCritique sourceAnchor ifNotNil: [ :anchor |
		dictionary
			at: 'entity'
			put: ([ anchor entity printString ]
				on: Error
				do: [ :e | 'unresolved anchor: ' , e messageText ]) ].
	^ dictionary
]

{ #category : 'tools - critics' }
MCPPharoTools class >> critiqueReportFor: critiques name: targetName [

	| shown |
	shown := critiques size > self maximumCritiquesShown
		ifTrue: [ critiques first: self maximumCritiquesShown ]
		ifFalse: [ critiques ].
	^ Dictionary new
		at: 'target' put: targetName;
		at: 'critiqueCount' put: shown size;
		at: 'totalCritiqueCount' put: critiques size;
		at: 'critiques' put: (shown collect: [ :each | self critiqueDictionaryFor: each ]) asArray;
		at: 'summary' put: (self formatCritiques: critiques forName: targetName);
		yourself
]

{ #category : 'tools - critics' }
MCPPharoTools class >> critiqueReportSchema [

	^ Dictionary new
		at: 'type' put: 'object';
		at: 'properties' put: (Dictionary new
			at: 'target' put: (self schemaPropertyOfType: 'string' describedAs: 'Class or package the critics were run on');
			at: 'critiqueCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Critiques listed');
			at: 'totalCritiqueCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Critiques found, which is larger when the list was cut');
			at: 'critiques' put: (Dictionary new
				at: 'type' put: 'array';
				at: 'description' put: 'One entry per critique';
				at: 'items' put: (Dictionary new
					at: 'type' put: 'object';
					at: 'properties' put: (Dictionary new
						at: 'rule' put: (self schemaPropertyOfType: 'string' describedAs: 'Name of the Renraku rule class');
						at: 'title' put: (self schemaPropertyOfType: 'string' describedAs: 'What the rule reports');
						at: 'entity' put: (self schemaPropertyOfType: 'string' describedAs: 'The class or method the critique is about');
						yourself);
					yourself);
				yourself);
			at: 'summary' put: (self schemaPropertyOfType: 'string' describedAs: 'The same report as human readable text');
			yourself);
		at: 'required' put: #( 'target' 'critiqueCount' 'totalCritiqueCount' 'critiques' 'summary' );
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> deleteMethod: selector fromClass: className side: side [

	| target |
	target := self classNamed: className side: side.
	(target includesSelector: selector asSymbol) ifFalse: [
		MCPToolError signal: 'method not found: ' , selector , ' in ' , className ].
	target removeSelector: selector asSymbol.
	^ 'Deleted: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , selector
]

{ #category : 'tools' }
MCPPharoTools class >> deleteMethodTool [

	^ (MCPTool
		name: 'delete_method'
		description: 'Remove a method from a class. Use side "class" for class-side methods. Cannot be undone — verify the selector before calling.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
				'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Method selector to remove (e.g. "printOn:" or "add:").').
				'side' -> self schemaSideProperty }
			required: #('class_name' 'selector'))
		handler: [ :args |
			self
				deleteMethod: (args at: 'selector')
				fromClass: (args at: 'class_name')
				side: (args at: 'side' ifAbsent: [ 'instance' ]) ])
		title: 'Delete a method';
		destructive;
		yourself
]

{ #category : 'tools' }
MCPPharoTools class >> evaluateTool [

	^ (MCPTool
		name: 'evaluate_pharo'
		description: 'Evaluate Pharo Smalltalk code and return the result as a string. Supports any valid Pharo expression or sequence of statements.'
		schema: (self
			schemaWithProperties: { 'code' -> (self schemaPropertyOfType: 'string' describedAs: 'Pharo Smalltalk code to evaluate') }
			required: #('code'))
		handler: [ :args |
			"No handler here: the request processor catches the error and marks the
			 tool result as a failure, which a handler returning a string cannot do."
			(OpalCompiler new evaluate: (args at: 'code')) printString ])
		title: 'Evaluate Pharo code';
		destructive;
		yourself
]

{ #category : 'browsing' }
MCPPharoTools class >> findImplementorsOf: selector [

	| results names |
	selector isEmpty ifTrue: [ MCPToolError signal: 'selector is required' ].
	results := SystemNavigation default allImplementorsOf: selector asSymbol.
	results isEmpty ifTrue: [ ^ 'No implementors found for: #' , selector ].
	names := (results collect: [ :m | m methodClass name ]) asSortedCollection.
	^ String streamContents: [ :s |
		s print: results size; << ' implementors of #'; << selector; nextPut: Character lf.
		names do: [ :n | s << n; nextPut: Character lf ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> findImplementorsTool [

	^ (MCPTool
		name: 'find_implementors'
		description: 'Find all classes that implement a given method selector.'
		schema: (self
			schemaWithProperties: { 'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Method selector to search for (e.g. printOn:)') }
			required: #('selector'))
		handler: [ :args | self findImplementorsOf: (args at: 'selector') ])
		title: 'Find the implementors of a selector';
		readOnly;
		yourself
]

{ #category : 'browsing' }
MCPPharoTools class >> findSendersOf: selector [

	| results sorted limited |
	selector isEmpty ifTrue: [ MCPToolError signal: 'selector is required' ].
	results := SystemNavigation default allSendersOf: selector asSymbol.
	results isEmpty ifTrue: [ ^ 'No senders found for: #' , selector ].
	sorted := (results collect: [ :m | m methodClass name , ' >> #' , m selector ]) asSortedCollection.
	limited := sorted size > 100 ifTrue: [ sorted first: 100 ] ifFalse: [ sorted ].
	^ String streamContents: [ :s |
		sorted size > 100 ifTrue: [
			s << 'Showing first 100 of '; print: sorted size; << ' senders';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :line | s << line; nextPut: Character lf ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> findSendersTool [

	^ (MCPTool
		name: 'find_senders'
		description: 'Find all methods that send a given message selector. Returns ClassName >> #selector per sender, capped at 100.'
		schema: (self
			schemaWithProperties: { 'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Message selector to search for (e.g. printString)') }
			required: #('selector'))
		handler: [ :args | self findSendersOf: (args at: 'selector') ])
		title: 'Find the senders of a selector';
		readOnly;
		yourself
]

{ #category : 'running' }
MCPPharoTools class >> formatCritiques: critiques forName: targetName [

	| limited |
	critiques isEmpty ifTrue: [ ^ 'No critiques found for: ' , targetName ].
	limited := critiques size > self maximumCritiquesShown
		ifTrue: [ critiques first: self maximumCritiquesShown ]
		ifFalse: [ critiques ].
	^ String streamContents: [ :s |
		limited size < critiques size ifTrue: [
			s << 'Showing first '; print: limited size; << ' of '; print: critiques size; << ' critiques';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :c |
			| dictionary |
			dictionary := self critiqueDictionaryFor: c.
			s << '['; << (dictionary at: 'rule'); << '] '; << (dictionary at: 'title').
			(dictionary at: 'entity' ifAbsent: [ nil ]) ifNotNil: [ :entity |
				s << ' ('; << entity; << ')' ].
			s nextPut: Character lf ] ]
]

{ #category : 'private' }
MCPPharoTools class >> formatPackageSummary: aPackage [
	| tc |
	tc := (aPackage classes select: [ :c | c inheritsFrom: TestCase ]) size.
	^ String streamContents: [ :s |
		s << aPackage name; << ' ('; print: aPackage classes size; << ' classes'.
		tc > 0 ifTrue: [ s << ', '; print: tc; << ' test classes' ].
		s << ')' ]
]

{ #category : 'running' }
MCPPharoTools class >> formatResult: result forName: targetName selector: selector duration: ms [
	^ String streamContents: [ :s |
		selector
			ifNil: [
				s << 'Ran '; print: result runCount; << ' tests in '; << targetName; nextPut: Character lf ]
			ifNotNil: [ :sel |
				s << 'Ran '; << targetName; << ' >> '; << sel; nextPut: Character lf ].
		s print: result passedCount; << ' passed'; nextPut: Character lf.
		s print: result unexpectedFailureCount; << ' failed'; nextPut: Character lf.
		s print: result unexpectedErrorCount; << ' errored'; nextPut: Character lf.
		s << '('; print: ms; << ' ms)'; nextPut: Character lf.
		result failureMessages ifNotEmpty: [
			s nextPut: Character lf; << '--- Failures ---'; nextPut: Character lf.
			result failureMessages keysAndValuesDo: [ :sel :msg |
				s << sel; nextPut: Character lf; << msg; nextPut: Character lf; nextPut: Character lf ] ].
		result errorMessages ifNotEmpty: [
			s nextPut: Character lf; << '--- Errors ---'; nextPut: Character lf.
			result errorMessages keysAndValuesDo: [ :sel :msg |
				s << sel; nextPut: Character lf; << msg; nextPut: Character lf; nextPut: Character lf ] ] ]
]

{ #category : 'browsing' }
MCPPharoTools class >> getClassComment: className [

	| cls |
	cls := self classNamed: className.
	cls comment isEmpty ifTrue: [ ^ '(no comment)' ].
	^ cls comment
]

{ #category : 'inspector' }
MCPPharoTools class >> hintsDescriptionFor: aTool [

	| annotations hints |
	annotations := aTool annotations.
	annotations ifNil: [ ^ '' ].
	hints := OrderedCollection new.
	(annotations at: 'readOnlyHint' ifAbsent: [ false ]) ifTrue: [ hints add: 'read only' ].
	(annotations at: 'destructiveHint' ifAbsent: [ false ]) ifTrue: [ hints add: 'destructive' ].
	(annotations at: 'idempotentHint' ifAbsent: [ false ]) ifTrue: [ hints add: 'idempotent' ].
	(annotations at: 'openWorldHint' ifAbsent: [ false ]) ifTrue: [ hints add: 'open world' ].
	^ ', ' join: hints
]

{ #category : 'inspector' }
MCPPharoTools class >> inspectorToolTable: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Tools'>

	"The annotations are read off each tool rather than listed here, so a tool built without
	 them shows an empty Hints cell instead of a wrong one."

	| tools |
	tools := (self allTools asSortedCollection: [ :a :b | a name < b name ]) asArray.
	^ aBuilder newTable
		items: tools;
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :each | each name ]);
		addColumn: (SpStringTableColumn title: 'Title' evaluated: [ :each | each title ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Hints' evaluated: [ :each | self hintsDescriptionFor: each ]);
		addColumn: (SpStringTableColumn title: 'Output schema' evaluated: [ :each |
			each outputSchema ifNil: [ '' ] ifNotNil: [ 'yes' ] ]);
		yourself
]

{ #category : 'tools' }
MCPPharoTools class >> listClassesMatching: pattern [
	| classes sorted limited header |
	classes := Smalltalk globals allClasses
		select: [ :c | c name asLowercase includesSubstring: pattern asLowercase ].
	classes isEmpty ifTrue: [ ^ 'No classes found matching: ' , pattern ].
	sorted := classes asSortedCollection: [ :a :b | a name < b name ].
	limited := sorted size > 50 ifTrue: [ sorted first: 50 ] ifFalse: [ sorted ].
	header := sorted size > 50
		ifTrue: [ 'Found ' , sorted size printString , ' classes (showing first 50):' , String lf ]
		ifFalse: [ '' ].
	^ header , (String streamContents: [ :s |
		limited do: [ :c | s nextPutAll: c name ] separatedBy: [ s nextPut: Character lf ] ])
]

{ #category : 'tools' }
MCPPharoTools class >> listClassesTool [

	^ (MCPTool
		name: 'list_classes'
		description: 'Search for classes in the Pharo image by name pattern. Returns up to 50 matching class names.'
		schema: (self
			schemaWithProperties: { 'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Substring to search for in class names (case-insensitive). Required — the image has thousands of classes.') }
			required: #('pattern'))
		handler: [ :args |
			| pattern |
			pattern := args at: 'pattern' ifAbsent: [ '' ].
			pattern isEmpty
				ifTrue: [ 'Provide a non-empty pattern. The image contains thousands of classes.' ]
				ifFalse: [ self listClassesMatching: pattern ] ])
		title: 'List classes';
		readOnly;
		yourself
]

{ #category : 'browsing' }
MCPPharoTools class >> listMethodsOn: className side: side [

	| target methods |
	target := self classNamed: className side: side.
	methods := target methods asSortedCollection: [ :a :b |
		a protocol name < b protocol name or: [
		a protocol name = b protocol name and: [
		a selector < b selector ] ] ].
	methods isEmpty ifTrue: [ ^ 'No methods defined on ' , className ].
	^ String streamContents: [ :s |
		methods do: [ :m |
			s << m protocol name; << ' | '; << m selector; nextPut: Character lf ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> listMethodsTool [

	^ (MCPTool
		name: 'list_methods'
		description: 'List all methods defined on a class with their protocol. Use side "class" for class-side methods.'
		schema: (self
			schemaWithProperties: {
				'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
				'side' -> self schemaSideProperty }
			required: #('className'))
		handler: [ :args |
			self
				listMethodsOn: (args at: 'className')
				side: (args at: 'side' ifAbsent: [ 'instance' ]) ])
		title: 'List the methods of a class';
		readOnly;
		yourself
]

{ #category : 'private' }
MCPPharoTools class >> listPackagesMatching: pattern [

	| allPkgs filtered sorted limited |
	allPkgs := Smalltalk packageOrganizer packages.
	filtered := pattern ifNil: [ allPkgs ] ifNotNil: [ :pat |
			            pat isEmpty
				            ifTrue: [ allPkgs ]
				            ifFalse: [
						            allPkgs select: [ :p |
							            p name asLowercase includesSubstring:
								            pat asLowercase ] ] ].
	filtered isEmpty ifTrue: [
		^ 'No packages found matching: ' , pattern printString ].
	sorted := filtered asSortedCollection: [ :a :b | a name < b name ].
	limited := sorted size > 200
		           ifTrue: [ sorted first: 200 ]
		           ifFalse: [ sorted ].
	^ String streamContents: [ :s |
			  sorted size > 200 ifTrue: [
					  s
						  << 'Showing first 200 of ';
						  print: sorted size;
						  << ' packages';
						  nextPut: Character lf;
						  nextPut: Character lf ].
			  limited do: [ :p |
					  s
						  << (self formatPackageSummary: p);
						  nextPut: Character lf ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> listPackagesTool [

	^ (MCPTool
		name: 'list_packages'
		description: 'List packages in the image with class and test class counts. Optionally filter by name pattern.'
		schema: (self
			schemaWithProperties: { 'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Optional substring to filter package names (case-insensitive)') }
			required: #())
		handler: [ :args |
			self listPackagesMatching: (args at: 'pattern' ifAbsent: [ nil ]) ])
		title: 'List packages';
		readOnly;
		yourself
]

{ #category : 'accessing' }
MCPPharoTools class >> maximumCritiquesShown [

	"Critiques beyond this count are summarised rather than listed: a package can raise
	 thousands, and a client pays for each one in its context window."

	^ 200
]

{ #category : 'tools - testing' }
MCPPharoTools class >> messageDictionariesFrom: aDictionary [

	^ aDictionary associations collect: [ :each |
		Dictionary new
			at: 'selector' put: each key;
			at: 'message' put: each value;
			yourself ]
]

{ #category : 'browsing' }
MCPPharoTools class >> methodSourceOf: methodName onClass: className side: side [

	| target |
	target := self classNamed: className side: side.
	^ target methodDictionary
		at: methodName asSymbol
		ifPresent: [ :method | method sourceCode ]
		ifAbsent: [
			MCPToolError signal: 'method not found: ' , methodName , ' in ' , target name ]
]

{ #category : 'tools' }
MCPPharoTools class >> methodSourceTool [

	^ (MCPTool
		name: 'method_source'
		description: 'Get the source code of a method. Use side "class" for class-side methods, "instance" for instance-side methods.'
		schema: (self
			schemaWithProperties: {
				'className' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class').
				'methodName' -> (self schemaPropertyOfType: 'string' describedAs: 'Selector of the method (e.g. "add:" or "printOn:")').
				'side' -> self schemaSideProperty }
			required: #( 'className' 'methodName' ))
		handler: [ :args |
			self
				methodSourceOf: (args at: 'methodName')
				onClass: (args at: 'className')
				side: (args at: 'side' ifAbsent: [ 'instance' ]) ])
		title: 'Show method source';
		readOnly;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> moveMethod: selector fromClass: sourceClassName side: side toClass: targetClassName [

	| srcTarget tgtTarget method protocol normalizedSource |
	srcTarget := self classNamed: sourceClassName as: 'source class' side: side.
	tgtTarget := self classNamed: targetClassName as: 'target class' side: side.
	(srcTarget includesSelector: selector asSymbol) ifFalse: [
		MCPToolError signal: 'method not found: ' , selector , ' in ' , sourceClassName ].
	(tgtTarget includesSelector: selector asSymbol) ifTrue: [
		MCPToolError signal: 'selector already defined in target: ' , selector , ' in ' , targetClassName ].
	method := srcTarget methodDictionary at: selector asSymbol.
	protocol := method protocol name.
	normalizedSource := method sourceCode
		copyReplaceAll: (String with: Character lf)
		with: (String with: Character cr).
	[ tgtTarget compile: normalizedSource classified: protocol asSymbol ]
		on: Error
		do: [ :e | MCPToolError signal: 'compile failed on target: ' , e messageText ].
	srcTarget removeSelector: selector asSymbol.
	^ 'Moved: ' , sourceClassName
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , selector , ' to ' , targetClassName
]

{ #category : 'tools' }
MCPPharoTools class >> moveMethodTool [

	^ (MCPTool
		name: 'method_move'
		description: 'Move a method from one class to another, preserving source and protocol. Fails if the target class already defines the selector.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Source class name').
				'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Selector to move').
				'target_class' -> (self schemaPropertyOfType: 'string' describedAs: 'Destination class name').
				'side' -> self schemaSideProperty }
			required: #('class_name' 'selector' 'target_class'))
		handler: [ :args |
			self
				moveMethod: (args at: 'selector')
				fromClass: (args at: 'class_name')
				side: (args at: 'side' ifAbsent: [ 'instance' ])
				toClass: (args at: 'target_class') ])
		title: 'Move a method to another class';
		additive;
		yourself
]

{ #category : 'private' }
MCPPharoTools class >> packageNamed: aString [

	"The package counterpart of classNamed:, with the same failure the caller reads."
	^ Smalltalk packageOrganizer packageNamed: aString ifAbsent: [
		MCPToolError signal: 'package not found: ' , aString ]
]

{ #category : 'registration' }
MCPPharoTools class >> registerToolsWith: aProcessor [
	self allTools do: [ :tool | aProcessor registerTool: tool ]
]

{ #category : 'editing' }
MCPPharoTools class >> removeClass: className [

	| cls |
	cls := self classNamed: className.
	cls subclasses isEmpty ifFalse: [
		MCPToolError signal: 'class has subclasses: ' , ((cls subclasses collect: [ :c | c name ]) joinUsing: ', ') ].
	cls removeFromSystem.
	^ 'Removed: ' , className
]

{ #category : 'tools' }
MCPPharoTools class >> removeClassTool [

	^ (MCPTool
		name: 'class_remove'
		description: 'Remove a class from the image. Fails if the class has subclasses. Cannot be undone — verify the class name before calling.'
		schema: (self
			schemaWithProperties: { 'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class to remove') }
			required: #('class_name'))
		handler: [ :args | self removeClass: (args at: 'class_name') ])
		title: 'Remove a class';
		destructive;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> removePackage: packageName [

	| pkg |
	pkg := self packageNamed: packageName.
	pkg classes isEmpty ifFalse: [
		MCPToolError signal: 'package not empty (' , pkg classes size printString , ' classes). Remove or move classes first.' ].
	Smalltalk packageOrganizer removePackage: pkg.
	^ 'Removed package: ' , packageName
]

{ #category : 'tools' }
MCPPharoTools class >> removePackageTool [

	^ (MCPTool
		name: 'package_remove'
		description: 'Remove an empty package from the image. Fails if the package still contains classes — remove or move them first.'
		schema: (self
			schemaWithProperties: { 'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name to remove') }
			required: #('package'))
		handler: [ :args | self removePackage: (args at: 'package') ])
		title: 'Remove a package';
		destructive;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> renameClass: oldName to: newName [

	(Smalltalk globals includesKey: oldName asSymbol) ifFalse: [
		MCPToolError signal: 'class not found: ' , oldName ].
	(Smalltalk globals includesKey: newName asSymbol) ifTrue: [
		MCPToolError signal: 'class already exists: ' , newName ].
	[ (RBRenameClassChange rename: oldName to: newName) execute ]
		on: Error
		do: [ :e | MCPToolError signal: 'rename failed: ' , e messageText ].
	^ 'Renamed: ' , oldName , ' to ' , newName
		, '. Use search_source to find references that need updating.'
]

{ #category : 'tools' }
MCPPharoTools class >> renameClassTool [

	^ (MCPTool
		name: 'class_rename'
		description: 'Rename a class in the image. Does not auto-update references in method source — use search_source after renaming to find callers that need updating.'
		schema: (self
			schemaWithProperties: {
				'old_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Current class name').
				'new_name' -> (self schemaPropertyOfType: 'string' describedAs: 'New class name. Must not already exist.') }
			required: #('old_name' 'new_name'))
		handler: [ :args |
			self renameClass: (args at: 'old_name') to: (args at: 'new_name') ])
		title: 'Rename a class';
		additive;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> renameMethod: oldSelector onClass: className side: side to: newSelector [

	| target oldMethod protocol newSource |
	target := self classNamed: className side: side.
	(target includesSelector: oldSelector asSymbol) ifFalse: [
		MCPToolError signal: 'method not found: ' , oldSelector , ' in ' , className ].
	(target includesSelector: newSelector asSymbol) ifTrue: [
		MCPToolError signal: 'selector already exists: ' , newSelector , ' in ' , className ].
	oldMethod := target methodDictionary at: oldSelector asSymbol.
	protocol := oldMethod protocol name.
	newSource := oldMethod sourceCode
		copyReplaceAll: oldSelector
		with: newSelector.
	[ target compile: newSource classified: protocol asSymbol ]
		on: Error
		do: [ :e | MCPToolError signal: 'recompile failed: ' , e messageText ].
	target removeSelector: oldSelector asSymbol.
	^ 'Renamed: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , oldSelector , ' to #' , newSelector
		, '. Use find_senders to update callers.'
]

{ #category : 'tools' }
MCPPharoTools class >> renameMethodTool [

	^ (MCPTool
		name: 'method_rename'
		description: 'Rename a method selector on a class. Rewrites the method source and removes the old selector. Does NOT auto-update senders — use find_senders after renaming to locate callers that need updating.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Name of the class that defines the method').
				'old_selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Current selector to rename').
				'new_selector' -> (self schemaPropertyOfType: 'string' describedAs: 'New selector. Must have the same number of arguments.').
				'side' -> self schemaSideProperty }
			required: #('class_name' 'old_selector' 'new_selector'))
		handler: [ :args |
			self
				renameMethod: (args at: 'old_selector')
				onClass: (args at: 'class_name')
				side: (args at: 'side' ifAbsent: [ 'instance' ])
				to: (args at: 'new_selector') ])
		title: 'Rename a method';
		additive;
		yourself
]

{ #category : 'tools - testing' }
MCPPharoTools class >> reportFor: result name: targetName selector: selector duration: ms [

	| report |
	report := Dictionary new
		at: 'target' put: targetName;
		at: 'runCount' put: result runCount;
		at: 'passedCount' put: result passedCount;
		at: 'failedCount' put: result unexpectedFailureCount;
		at: 'erroredCount' put: result unexpectedErrorCount;
		at: 'durationMilliseconds' put: ms;
		at: 'failures' put: (self messageDictionariesFrom: result failureMessages);
		at: 'errors' put: (self messageDictionariesFrom: result errorMessages);
		at: 'summary' put: (self formatResult: result forName: targetName selector: selector duration: ms);
		yourself.
	selector ifNotNil: [ :sel | report at: 'selector' put: sel ].
	^ report
]

{ #category : 'quality' }
MCPPharoTools class >> runCriticsOnClass: className [

	| cls |
	cls := self classNamed: className.
	^ self critiqueReportFor: (self collectCritiquesForClass: cls) name: className
]

{ #category : 'quality' }
MCPPharoTools class >> runCriticsOnPackage: packageName [

	| critiques |
	critiques := OrderedCollection new.
	(self packageNamed: packageName) classes do: [ :cls |
		critiques addAll: (self collectCritiquesForClass: cls) ].
	^ self critiqueReportFor: critiques name: packageName
]

{ #category : 'tools' }
MCPPharoTools class >> runCriticsTool [

	^ (MCPTool
		name: 'run_critics'
		description: 'Run Renraku code critics on a class or all classes in a package. Returns rule violations with descriptions.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Class to critique. Required unless package given.').
				'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name — critiques all classes. Overrides class_name.') }
			required: #())
		handler: [ :args |
			(args at: 'package' ifAbsent: [ nil ])
				ifNotNil: [ :package | self runCriticsOnPackage: package ]
				ifNil: [
					(args at: 'class_name' ifAbsent: [ nil ])
						ifNil: [ MCPToolError signal: 'provide class_name or package' ]
						ifNotNil: [ :className | self runCriticsOnClass: className ] ] ])
		title: 'Run the code critics';
		outputSchema: self critiqueReportSchema;
		readOnly;
		yourself
]

{ #category : 'quality' }
MCPPharoTools class >> runTestsForClass: className selector: selector [

	| cls suite result ms |
	cls := self classNamed: className.
	(cls inheritsFrom: TestCase) ifFalse: [
		MCPToolError signal: className , ' is not a TestCase subclass' ].
	suite := selector
		ifNil: [ cls suite ]
		ifNotNil: [ :sel |
			TestSuite new
				addTest: (cls selector: sel asSymbol);
				yourself ].
	result := MCPTestResult new.
	ms := Time millisecondsToRun: [ suite run: result ].
	^ self reportFor: result name: className selector: selector duration: ms
]

{ #category : 'quality' }
MCPPharoTools class >> runTestsInPackage: packageName [

	| pkg classes suite result ms |
	pkg := self packageNamed: packageName.
	classes := pkg classes select: [ :c | c inheritsFrom: TestCase ].
	classes isEmpty ifTrue: [
		MCPToolError signal: 'no TestCase subclasses in package: ' , packageName ].
	suite := TestSuite new.
	classes do: [ :c | c suite tests do: [ :t | suite addTest: t ] ].
	result := MCPTestResult new.
	ms := Time millisecondsToRun: [ suite run: result ].
	^ self reportFor: result name: packageName selector: nil duration: ms
]

{ #category : 'tools' }
MCPPharoTools class >> runTestsTool [

	^ (MCPTool
		name: 'run_tests'
		description: 'Run a TestCase subclass, a single test method, or all TestCase subclasses in a package. Returns pass/fail/error counts and failure messages.'
		schema: (self
			schemaWithProperties: {
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'TestCase subclass name. Required unless package is given.').
				'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Single test method selector. Omit to run all tests.').
				'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name — runs all TestCase subclasses. Overrides class_name.') }
			required: #())
		handler: [ :args |
			(args at: 'package' ifAbsent: [ nil ])
				ifNotNil: [ :package | self runTestsInPackage: package ]
				ifNil: [
					(args at: 'class_name' ifAbsent: [ nil ])
						ifNil: [ MCPToolError signal: 'provide class_name or package' ]
						ifNotNil: [ :className |
							self
								runTestsForClass: className
								selector: (args at: 'selector' ifAbsent: [ nil ]) ] ] ])
		title: 'Run tests';
		outputSchema: self testReportSchema;
		additive;
		yourself
]

{ #category : 'tools - schemas' }
MCPPharoTools class >> schemaArrayOfMessagesDescribedAs: aDescription [

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

{ #category : 'tools - schemas' }
MCPPharoTools class >> schemaPropertyOfType: aTypeName describedAs: aDescription [

	^ Dictionary new
		at: 'type' put: aTypeName;
		at: 'description' put: aDescription;
		yourself
]

{ #category : 'schemas' }
MCPPharoTools class >> schemaPropertyOneOf: allowedValues describedAs: aDescription [

	^ Dictionary new
		at: 'type' put: 'string';
		at: 'enum' put: allowedValues;
		at: 'description' put: aDescription;
		yourself
]

{ #category : 'schemas' }
MCPPharoTools class >> schemaSideProperty [

	"The side argument six tools take. It means the same in each of them, so it reads the same."
	^ self
		schemaPropertyOneOf: #( 'instance' 'class' )
		describedAs: 'Whether the method is on the instance side or the class side. Defaults to instance.'
]

{ #category : 'schemas' }
MCPPharoTools class >> schemaWithProperties: propertyAssociations required: requiredNames [

	"The JSON Schema shape every tool declares. A factory states the properties it takes and the
	 names a call must carry, and nothing else."
	^ Dictionary new
		at: 'type' put: 'object';
		at: 'properties' put: propertyAssociations asDictionary;
		at: 'required' put: requiredNames;
		yourself
]

{ #category : 'running' }
MCPPharoTools class >> searchSource: pattern inMethods: methods caseSensitive: caseSensitive [
	| norm results limited |
	norm := caseSensitive ifTrue: [ pattern ] ifFalse: [ pattern asLowercase ].
	results := methods select: [ :m |
		(caseSensitive ifTrue: [ m sourceCode ] ifFalse: [ m sourceCode asLowercase ])
			includesSubstring: norm ].
	results isEmpty ifTrue: [ ^ 'No methods found containing: ' , pattern ].
	limited := results size > 100 ifTrue: [ results first: 100 ] ifFalse: [ results ].
	^ String streamContents: [ :s |
		results size > 100 ifTrue: [
			s << 'Showing first 100 of '; print: results size; << ' matches';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :m | self writeMatchEntry: m norm: norm to: s ] ]
]

{ #category : 'browsing' }
MCPPharoTools class >> searchSourceFor: pattern inClass: className caseSensitive: caseSensitive [

	| cls methods |
	cls := self classNamed: className.
	methods := cls methods , cls class methods.
	^ self searchSource: pattern inMethods: methods caseSensitive: caseSensitive
]

{ #category : 'browsing' }
MCPPharoTools class >> searchSourceFor: pattern inPackage: packageName caseSensitive: caseSensitive [

	| pkg methods |
	pkg := self packageNamed: packageName.
	methods := pkg classes flatCollect: [ :cls | cls methods , cls class methods ].
	^ self searchSource: pattern inMethods: methods caseSensitive: caseSensitive
]

{ #category : 'tools' }
MCPPharoTools class >> searchSourceTool [

	^ (MCPTool
		name: 'search_source'
		description: 'Search method source code for a text pattern across a class or package. Returns matching method names with the first matching line. Use for finding string literals, comments, or any text that find_implementors/find_senders cannot locate.'
		schema: (self
			schemaWithProperties: {
				'pattern' -> (self schemaPropertyOfType: 'string' describedAs: 'Text to search for in method source code').
				'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'Search methods of this class (instance + class side). Required unless package given.').
				'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Search all methods in this package. Overrides class_name.').
				'case_sensitive' -> (self schemaPropertyOfType: 'boolean' describedAs: 'Case-sensitive match. Defaults to false.') }
			required: #('pattern'))
		handler: [ :args |
			| pattern cs |
			pattern := args at: 'pattern'.
			cs := args at: 'case_sensitive' ifAbsent: [ false ].
			(args at: 'package' ifAbsent: [ nil ])
				ifNotNil: [ :package | self searchSourceFor: pattern inPackage: package caseSensitive: cs ]
				ifNil: [
					(args at: 'class_name' ifAbsent: [ nil ])
						ifNotNil: [ :className | self searchSourceFor: pattern inClass: className caseSensitive: cs ]
						ifNil: [ MCPToolError signal: 'provide class_name or package' ] ] ])
		title: 'Search method source';
		readOnly;
		yourself
]

{ #category : 'editing' }
MCPPharoTools class >> setClassComment: comment onClass: className [

	(self classNamed: className) comment: comment.
	^ 'Comment set on: ' , className
]

{ #category : 'tools - testing' }
MCPPharoTools class >> testReportSchema [

	^ Dictionary new
		at: 'type' put: 'object';
		at: 'properties' put: (Dictionary new
			at: 'target' put: (self schemaPropertyOfType: 'string' describedAs: 'Class or package the tests were run for');
			at: 'selector' put: (self schemaPropertyOfType: 'string' describedAs: 'The one test method run, absent when all were run');
			at: 'runCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Tests run');
			at: 'passedCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Tests that passed');
			at: 'failedCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Tests that failed an assertion');
			at: 'erroredCount' put: (self schemaPropertyOfType: 'integer' describedAs: 'Tests that raised an error');
			at: 'durationMilliseconds' put: (self schemaPropertyOfType: 'integer' describedAs: 'Milliseconds the suite took');
			at: 'failures' put: (self schemaArrayOfMessagesDescribedAs: 'One entry per failed test');
			at: 'errors' put: (self schemaArrayOfMessagesDescribedAs: 'One entry per errored test');
			at: 'summary' put: (self schemaPropertyOfType: 'string' describedAs: 'The same report as human readable text');
			yourself);
		at: 'required' put: #( 'target' 'runCount' 'passedCount' 'failedCount' 'erroredCount' 'summary' );
		yourself
]

{ #category : 'private' }
MCPPharoTools class >> writeMatchEntry: m norm: norm to: s [

	| matchLine |
	s
		<< m methodClass name;
		<< ' >> #';
		<< m selector;
		nextPut: Character lf.
	matchLine := m sourceCode lines detect: [ :l | l asLowercase includesSubstring: norm ] ifNone: [ nil ].
	matchLine ifNotNil: [
			s
				<< '  ';
				<< matchLine trimBoth;
				nextPut: Character lf ]
]
