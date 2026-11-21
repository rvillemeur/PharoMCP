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

	^ MCPClassCommentTool new
]

{ #category : 'tools' }
MCPPharoTools class >> classDefinitionTool [

	^ MCPClassDefinitionTool new
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

	^ MCPClassHierarchyTool new
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

	^ MCPCompileMethodTool new
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

	^ MCPCreateClassTool new
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

	^ MCPCreatePackageTool new
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

	^ MCPDeleteMethodTool new
]

{ #category : 'tools' }
MCPPharoTools class >> evaluateTool [

	^ MCPEvaluateTool new
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

	^ MCPFindImplementorsTool new
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

	^ MCPFindSendersTool new
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

	^ MCPListClassesTool new
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

	^ MCPListMethodsTool new
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

	^ MCPListPackagesTool new
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

	^ MCPMethodSourceTool new
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

	^ MCPMoveMethodTool new
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

	^ MCPRemoveClassTool new
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

	^ MCPRemovePackageTool new
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

	^ MCPRenameClassTool new
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

	^ MCPRenameMethodTool new
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

	^ MCPRunCriticsTool new
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

	^ MCPRunTestsTool new
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

	^ MCPSearchSourceTool new
]

{ #category : 'editing' }
MCPPharoTools class >> setClassComment: comment onClass: className [

	(self classNamed: className) comment: comment.
	^ 'Comment set on: ' , className
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
