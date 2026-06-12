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
		add: self renameMethodTool; add: self createClassTool; add: self removeClassTool;
		add: self classCommentTool; add: self listMethodsTool; add: self searchSourceTool;
		add: self runTestsTool; add: self runCriticsTool; add: self findSendersTool;
		add: self findImplementorsTool; add: self listPackagesTool; add: self createPackageTool;
		add: self classHierarchyTool;
		yourself) asArray
]

{ #category : 'tools' }
MCPPharoTools class >> classCommentTool [
	^ MCPTool
		name: 'class_comment'
		description: 'Get or set the comment (documentation) on a class. Omit the comment parameter to read; supply it to write.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class';
					yourself);
				at: 'comment' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'New comment text. Omit to read the current comment.';
					yourself);
				yourself);
			at: 'required' put: #('class_name');
			yourself)
		handler: [ :args |
			| className comment |
			className := args at: 'class_name' ifAbsent: [ nil ].
			className ifNil: [ 'Error: class_name is required' ] ifNotNil: [
				comment := args at: 'comment' ifAbsent: [ nil ].
				comment
					ifNil: [ MCPPharoTools getClassComment: className ]
					ifNotNil: [ MCPPharoTools setClassComment: comment onClass: className ] ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> classDefinitionTool [
	^ MCPTool
		name: 'class_definition'
		description: 'Get the definition of a Pharo class including its superclass, instance variables, and package.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'className' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Exact name of the class';
					yourself);
				yourself);
			at: 'required' put: #('className');
			yourself)
		handler: [ :args |
			args at: 'className'
				ifPresent: [ :className |
					Smalltalk globals
						at: className asSymbol
						ifPresent: [ :class | class definitionString ]
						ifAbsent: [ 'Error: class not found: ' , className ] ]
				ifAbsent: [ 'Error: missing className' ] ]
]

{ #category : 'running' }
MCPPharoTools class >> classHierarchyOf: className [
	| cls superchain subs |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
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
	^ MCPTool
		name: 'class_hierarchy'
		description: 'Show superclass chain and direct subclasses of a class.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Name of the class'; yourself);
				yourself);
			at: 'required' put: #('class_name');
			yourself)
		handler: [ :args |
			| cls |
			cls := args at: 'class_name' ifAbsent: [ nil ].
			cls ifNil: [ 'Error: class_name is required' ]
			ifNotNil: [ MCPPharoTools classHierarchyOf: cls ] ]
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

{ #category : 'running' }
MCPPharoTools class >> compileMethod: source onClass: className side: side classified: protocol [
	| cls target normalizedSource selector |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	target := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	normalizedSource := source
		copyReplaceAll: (String with: Character lf)
		with: (String with: Character cr).
	selector := [ target compile: normalizedSource classified: protocol asSymbol ]
		on: Error
		do: [ :e | ^ 'Error: compilation failed: ' , e messageText ].
	^ 'Compiled: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , selector
]

{ #category : 'tools' }
MCPPharoTools class >> compileMethodTool [
	^ MCPTool
		name: 'compile_method'
		description: 'Compile a method on a class. Returns the selector on success. Use side "class" for class-side methods. LF line endings are normalised automatically.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class';
					yourself);
				at: 'source' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Full method source including selector';
					yourself);
				at: 'side' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'enum' put: #('instance' 'class');
					at: 'description' put: 'Instance or class side. Defaults to instance.';
					yourself);
				at: 'protocol' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Protocol name. Defaults to ''as yet unclassified''.';
					yourself);
				yourself);
			at: 'required' put: #('class_name' 'source');
			yourself)
		handler: [ :args |
			| className source side protocol |
			className := args at: 'class_name' ifAbsent: [ nil ].
			source := args at: 'source' ifAbsent: [ nil ].
			side := args at: 'side' ifAbsent: [ 'instance' ].
			protocol := args at: 'protocol' ifAbsent: [ 'as yet unclassified' ].
			(className isNil or: [ source isNil ])
				ifTrue: [ 'Error: class_name and source are required' ]
				ifFalse: [ self compileMethod: source onClass: className side: side classified: protocol ] ]
]

{ #category : 'running' }
MCPPharoTools class >> createClass: className superclass: superclsName instanceVariables: instVarNames package: packageName [
	| supercls slots |
	(Smalltalk globals includesKey: className asSymbol) ifTrue: [
		^ 'Error: class already exists: ' , className ].
	supercls := Smalltalk globals at: superclsName asSymbol
		ifAbsent: [ ^ 'Error: superclass not found: ' , superclsName ].
	slots := (instVarNames ifNil: [ #() ]) collect: [ :n | n asSymbol ].
	[ (supercls << className asSymbol
		slots: slots;
		package: packageName) install ]
		on: Error
		do: [ :e | ^ 'Error: class creation failed: ' , e messageText ].
	^ 'Created: ' , className
		, ' (subclass of ' , superclsName
		, ', ' , slots size printString , ' instance variable'
		, (slots size = 1 ifTrue: [ '' ] ifFalse: [ 's' ])
		, ')'
]

{ #category : 'tools' }
MCPPharoTools class >> createClassTool [
	^ MCPTool
		name: 'class_create'
		description: 'Create a new Pharo class. Fails if the class already exists. Use compile_method to add methods after creation.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the new class';
					yourself);
				at: 'superclass_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Superclass name. Defaults to Object.';
					yourself);
				at: 'instance_variables' put: (Dictionary new
					at: 'type' put: 'array';
					at: 'items' put: (Dictionary new at: 'type' put: 'string'; yourself);
					at: 'description' put: 'Instance variable names. Defaults to none.';
					yourself);
				at: 'package' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Package name, e.g. MyApp or MyApp-Core.';
					yourself);
				yourself);
			at: 'required' put: #('class_name' 'package');
			yourself)
		handler: [ :args |
			| className superclsName instVars package |
			className := args at: 'class_name' ifAbsent: [ nil ].
			package := args at: 'package' ifAbsent: [ nil ].
			(className isNil or: [ package isNil ])
				ifTrue: [ 'Error: class_name and package are required' ]
				ifFalse: [
					superclsName := args at: 'superclass_name' ifAbsent: [ 'Object' ].
					instVars := args at: 'instance_variables' ifAbsent: [ #() ].
					self createClass: className superclass: superclsName instanceVariables: instVars package: package ] ]
]

{ #category : 'running' }
MCPPharoTools class >> createPackage: packageName [
	(Smalltalk packageOrganizer hasPackage: packageName) ifTrue: [
		^ 'Error: package already exists: ' , packageName ].
	Smalltalk packageOrganizer ensurePackage: packageName.
	^ 'Created package: ' , packageName
]

{ #category : 'tools' }
MCPPharoTools class >> createPackageTool [
	^ MCPTool
		name: 'package_create'
		description: 'Create a new package in the image. Fails if a package with that name already exists.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'package' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Package name, e.g. MyApp or MyApp-Core';
					yourself);
				yourself);
			at: 'required' put: #('package');
			yourself)
		handler: [ :args |
			| pkg |
			pkg := args at: 'package' ifAbsent: [ nil ].
			pkg ifNil: [ 'Error: package is required' ]
			ifNotNil: [ MCPPharoTools createPackage: pkg ] ]
]

{ #category : 'running' }
MCPPharoTools class >> deleteMethod: selector fromClass: className side: side [
	| cls target |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	target := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	(target includesSelector: selector asSymbol) ifFalse: [
		^ 'Error: method not found: ' , selector , ' in ' , className ].
	target removeSelector: selector asSymbol.
	^ 'Deleted: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , selector
]

{ #category : 'tools' }
MCPPharoTools class >> deleteMethodTool [
	^ MCPTool
		name: 'delete_method'
		description: 'Remove a method from a class. Use side "class" for class-side methods. Cannot be undone — verify the selector before calling.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class';
					yourself);
				at: 'selector' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Method selector to remove (e.g. "printOn:" or "add:").';
					yourself);
				at: 'side' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'enum' put: #('instance' 'class');
					at: 'description' put: 'Instance or class side. Defaults to instance.';
					yourself);
				yourself);
			at: 'required' put: #('class_name' 'selector');
			yourself)
		handler: [ :args |
			| className selector side |
			className := args at: 'class_name' ifAbsent: [ nil ].
			selector := args at: 'selector' ifAbsent: [ nil ].
			side := args at: 'side' ifAbsent: [ 'instance' ].
			(className isNil or: [ selector isNil ])
				ifTrue: [ 'Error: class_name and selector are required' ]
				ifFalse: [ self deleteMethod: selector fromClass: className side: side ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> evaluateTool [
	^ MCPTool
		name: 'evaluate_pharo'
		description: 'Evaluate Pharo Smalltalk code and return the result as a string. Supports any valid Pharo expression or sequence of statements.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'code' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Pharo Smalltalk code to evaluate';
					yourself);
				yourself);
			at: 'required' put: #('code');
			yourself)
		handler: [ :args |
			args at: 'code'
				ifPresent: [ :code |
					[ (OpalCompiler new evaluate: code) printString ]
						on: Error
						do: [ :e | 'Error: ' , e messageText ] ]
				ifAbsent: [ 'Error: missing code argument' ] ]
]

{ #category : 'running' }
MCPPharoTools class >> findImplementorsOf: selector [
	| results names |
	selector isEmpty ifTrue: [ ^ 'Error: selector is required' ].
	results := SystemNavigation default allImplementorsOf: selector asSymbol.
	results isEmpty ifTrue: [ ^ 'No implementors found for: #' , selector ].
	names := (results collect: [ :m | m methodClass name ]) asSortedCollection.
	^ String streamContents: [ :s |
		s print: results size; << ' implementors of #'; << selector; nextPut: Character lf.
		names do: [ :n | s << n; nextPut: Character lf ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> findImplementorsTool [
	^ MCPTool
		name: 'find_implementors'
		description: 'Find all classes that implement a given method selector.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'selector' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Method selector to search for (e.g. printOn:)'; yourself);
				yourself);
			at: 'required' put: #('selector');
			yourself)
		handler: [ :args |
			| sel |
			sel := args at: 'selector' ifAbsent: [ nil ].
			sel ifNil: [ 'Error: selector is required' ]
			ifNotNil: [ MCPPharoTools findImplementorsOf: sel ] ]
]

{ #category : 'running' }
MCPPharoTools class >> findSendersOf: selector [
	| results sorted limited |
	selector isEmpty ifTrue: [ ^ 'Error: selector is required' ].
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
	^ MCPTool
		name: 'find_senders'
		description: 'Find all methods that send a given message selector. Returns ClassName >> #selector per sender, capped at 100.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'selector' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Message selector to search for (e.g. printString)'; yourself);
				yourself);
			at: 'required' put: #('selector');
			yourself)
		handler: [ :args |
			| sel |
			sel := args at: 'selector' ifAbsent: [ nil ].
			sel ifNil: [ 'Error: selector is required' ]
			ifNotNil: [ MCPPharoTools findSendersOf: sel ] ]
]

{ #category : 'running' }
MCPPharoTools class >> formatCritiques: critiques forName: targetName [
	| limited |
	critiques isEmpty ifTrue: [ ^ 'No critiques found for: ' , targetName ].
	limited := critiques size > 200
		ifTrue: [ critiques first: 200 ]
		ifFalse: [ critiques ].
	^ String streamContents: [ :s |
		critiques size > 200 ifTrue: [
			s << 'Showing first 200 of '; print: critiques size; << ' critiques';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :c |
			s << '['; << c rule class name; << '] '; << c title.
			c sourceAnchor ifNotNil: [ :a |
				| entity |
				entity := [ a entity ] on: Error do: [ :e | nil ].
				entity ifNotNil: [ s << ' ('; << entity printString; << ')' ] ].
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

{ #category : 'running' }
MCPPharoTools class >> getClassComment: className [
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	cls comment isEmpty ifTrue: [ ^ '(no comment)' ].
	^ cls comment
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
	^ MCPTool
		name: 'list_classes'
		description: 'Search for classes in the Pharo image by name pattern. Returns up to 50 matching class names.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'pattern' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Substring to search for in class names (case-insensitive). Required — the image has thousands of classes.';
					yourself);
				yourself);
			at: 'required' put: #('pattern');
			yourself)
		handler: [ :args |
			| pattern |
			pattern := args at: 'pattern' ifAbsent: [ '' ].
			pattern isEmpty
				ifTrue: [ 'Provide a non-empty pattern. The image contains thousands of classes.' ]
				ifFalse: [ MCPPharoTools listClassesMatching: pattern ] ]
]

{ #category : 'tools' }
MCPPharoTools class >> listMethodsTool [
	^ MCPTool
		name: 'list_methods'
		description: 'List all methods defined on a class with their protocol. Use side "class" for class-side methods.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'className' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class';
					yourself);
				at: 'side' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'enum' put: #('instance' 'class');
					at: 'description' put: 'Whether to list instance-side or class-side methods. Defaults to instance.';
					yourself);
				yourself);
			at: 'required' put: #('className');
			yourself)
		handler: [ :args |
			| className side cls target methods |
			className := args at: 'className' ifAbsent: [ nil ].
			className ifNil: [ 'Error: missing className' ] ifNotNil: [
				cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
				side := (args at: 'side' ifAbsent: [ 'instance' ]) = 'class'.
				target := side ifTrue: [ cls class ] ifFalse: [ cls ].
				methods := target methods asSortedCollection: [ :a :b |
					a protocol name < b protocol name or: [
					a protocol name = b protocol name and: [ a selector < b selector ] ] ].
				methods isEmpty
					ifTrue: [ 'No methods defined on ' , className ]
					ifFalse: [
						String streamContents: [ :s |
							methods do: [ :m |
								s << m protocol name; << ' | '; << m selector; nextPut: Character lf ] ] ] ] ]
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
	^ MCPTool
		name: 'list_packages'
		description: 'List packages in the image with class and test class counts. Optionally filter by name pattern.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'pattern' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Optional substring to filter package names (case-insensitive)'; yourself);
				yourself);
			at: 'required' put: #();
			yourself)
		handler: [ :args |
			MCPPharoTools listPackagesMatching: (args at: 'pattern' ifAbsent: [ nil ]) ]
]

{ #category : 'tools' }
MCPPharoTools class >> methodSourceTool [

	^ MCPTool
		  name: 'method_source'
		  description:
		  'Get the source code of a method. Use side "class" for class-side methods, "instance" for instance-side methods.'
		  schema: (Dictionary new
				   at: 'type' put: 'object';
				   at: 'properties' put: (Dictionary new
						    at: 'className' put: (Dictionary new
								     at: 'type' put: 'string';
								     at: 'description' put: 'Name of the class';
								     yourself);
						    at: 'methodName' put: (Dictionary new
							     at: 'type' put: 'string';
							     at: 'description'
							     put: 'Selector of the method (e.g. "add:" or "printOn:")';
							     yourself);
						    at: 'side' put: (Dictionary new
							     at: 'type' put: 'string';
							     at: 'enum' put: #( 'instance' 'class' );
							     at: 'description'
							     put:
								     'Whether to look on the instance side or class side. Defaults to instance.';
							     yourself);
						    yourself);
				   at: 'required' put: #( 'className' 'methodName' );
				   yourself)
		  handler: [ :args |
				  args
					  at: 'className'
					  ifPresent: [ :className |
							  args
								  at: 'methodName'
								  ifPresent: [ :methodName |
										  | class side |
										  class := Smalltalk globals
											           at: className asSymbol
											           ifAbsent: [ nil ].
										  class
											  ifNil: [ 'Error: class not found: ' , className ]
											  ifNotNil: [
													  side := (args at: 'side' ifAbsent: [ 'instance' ])
													          = 'class'
														          ifTrue: [ class class ]
														          ifFalse: [ class ].
													  side methodDictionary
														  at: methodName asSymbol
														  ifPresent: [ :method | method sourceCode ]
														  ifAbsent: [
														  'Error: method not found: ' , methodName , ' in '
														  , class name ] ] ]
								  ifAbsent: [ 'Error: missing methodName' ] ]
					  ifAbsent: [ 'Error: missing className' ] ]
]

{ #category : 'registration' }
MCPPharoTools class >> registerToolsWith: aProcessor [
	self allTools do: [ :tool | aProcessor registerTool: tool ]
]

{ #category : 'running' }
MCPPharoTools class >> removeClass: className [
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	cls subclasses isEmpty ifFalse: [
		^ 'Error: class has subclasses: ' , ((cls subclasses collect: [ :c | c name ]) joinUsing: ', ') ].
	cls removeFromSystem.
	^ 'Removed: ' , className
]

{ #category : 'tools' }
MCPPharoTools class >> removeClassTool [
	^ MCPTool
		name: 'class_remove'
		description: 'Remove a class from the image. Fails if the class has subclasses. Cannot be undone — verify the class name before calling.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class to remove';
					yourself);
				yourself);
			at: 'required' put: #('class_name');
			yourself)
		handler: [ :args |
			| className |
			className := args at: 'class_name' ifAbsent: [ nil ].
			className ifNil: [ 'Error: class_name is required' ]
			ifNotNil: [ MCPPharoTools removeClass: className ] ]
]

{ #category : 'running' }
MCPPharoTools class >> renameMethod: oldSelector onClass: className side: side to: newSelector [
	| cls target permutation oldMethod protocol newSource |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	target := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	(target includesSelector: oldSelector asSymbol) ifFalse: [
		^ 'Error: method not found: ' , oldSelector , ' in ' , className ].
	(target includesSelector: newSelector asSymbol) ifTrue: [
		^ 'Error: selector already exists: ' , newSelector , ' in ' , className ].
	oldMethod := target methodDictionary at: oldSelector asSymbol.
	protocol := oldMethod protocol name.
	newSource := oldMethod sourceCode
		copyReplaceAll: oldSelector
		with: newSelector.
	permutation := (1 to: oldSelector asSymbol numArgs) asArray.
	[ target compile: newSource classified: protocol asSymbol ]
		on: Error
		do: [ :e | ^ 'Error: recompile failed: ' , e messageText ].
	target removeSelector: oldSelector asSymbol.
	^ 'Renamed: ' , className
		, (side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ])
		, ' >> #' , oldSelector , ' to #' , newSelector
		, '. Use find_senders to update callers.'
]

{ #category : 'tools' }
MCPPharoTools class >> renameMethodTool [
	^ MCPTool
		name: 'method_rename'
		description: 'Rename a method selector on a class. Rewrites the method source and removes the old selector. Does NOT auto-update senders — use find_senders after renaming to locate callers that need updating.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class that defines the method';
					yourself);
				at: 'old_selector' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Current selector to rename';
					yourself);
				at: 'new_selector' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'New selector. Must have the same number of arguments.';
					yourself);
				at: 'side' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'enum' put: #('instance' 'class');
					at: 'description' put: 'Instance or class side. Defaults to instance.';
					yourself);
				yourself);
			at: 'required' put: #('class_name' 'old_selector' 'new_selector');
			yourself)
		handler: [ :args |
			| className oldSel newSel side |
			className := args at: 'class_name' ifAbsent: [ nil ].
			oldSel := args at: 'old_selector' ifAbsent: [ nil ].
			newSel := args at: 'new_selector' ifAbsent: [ nil ].
			(className isNil or: [ oldSel isNil or: [ newSel isNil ] ])
				ifTrue: [ 'Error: class_name, old_selector and new_selector are required' ]
				ifFalse: [
					side := args at: 'side' ifAbsent: [ 'instance' ].
					MCPPharoTools renameMethod: oldSel onClass: className side: side to: newSel ] ]
]

{ #category : 'running' }
MCPPharoTools class >> runCriticsOnClass: className [
	| cls critiques |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	critiques := self collectCritiquesForClass: cls.
	^ self formatCritiques: critiques forName: className
]

{ #category : 'running' }
MCPPharoTools class >> runCriticsOnPackage: packageName [
	| pkg critiques |
	pkg := Smalltalk packageOrganizer packageNamed: packageName ifAbsent: [ ^ 'Error: package not found: ' , packageName ].
	critiques := OrderedCollection new.
	pkg classes do: [ :cls | critiques addAll: (self collectCritiquesForClass: cls) ].
	^ self formatCritiques: critiques forName: packageName
]

{ #category : 'tools' }
MCPPharoTools class >> runCriticsTool [
	^ MCPTool
		name: 'run_critics'
		description: 'Run Renraku code critics on a class or all classes in a package. Returns rule violations with descriptions.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Class to critique. Required unless package given.'; yourself);
				at: 'package' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Package name — critiques all classes. Overrides class_name.'; yourself);
				yourself);
			at: 'required' put: #();
			yourself)
		handler: [ :args |
			| pkg cls |
			pkg := args at: 'package' ifAbsent: [ nil ].
			cls := args at: 'class_name' ifAbsent: [ nil ].
			pkg ifNotNil: [ MCPPharoTools runCriticsOnPackage: pkg ]
			ifNil: [ cls ifNil: [ 'Error: provide class_name or package' ]
				ifNotNil: [ MCPPharoTools runCriticsOnClass: cls ] ] ]
]

{ #category : 'running' }
MCPPharoTools class >> runTestsForClass: className selector: selector [
	| cls suite result ms |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	(cls inheritsFrom: TestCase) ifFalse: [
		^ 'Error: ' , className , ' is not a TestCase subclass' ].
	suite := selector
		ifNil: [ cls suite ]
		ifNotNil: [ :sel |
			TestSuite new
				addTest: (cls selector: sel asSymbol);
				yourself ].
	result := MCPTestResult new.
	ms := Time millisecondsToRun: [ suite run: result ].
	^ self formatResult: result forName: className selector: selector duration: ms
]

{ #category : 'running' }
MCPPharoTools class >> runTestsInPackage: packageName [
	| pkg classes suite result ms |
	pkg := Smalltalk packageOrganizer packageNamed: packageName ifAbsent: [ ^ 'Error: package not found: ' , packageName ].
	classes := pkg classes select: [ :c | c inheritsFrom: TestCase ].
	classes isEmpty ifTrue: [ ^ 'Error: no TestCase subclasses in package: ' , packageName ].
	suite := TestSuite new.
	classes do: [ :c | c suite tests do: [ :t | suite addTest: t ] ].
	result := MCPTestResult new.
	ms := Time millisecondsToRun: [ suite run: result ].
	^ self formatResult: result forName: packageName selector: nil duration: ms
]

{ #category : 'tools' }
MCPPharoTools class >> runTestsTool [
	^ MCPTool
		name: 'run_tests'
		description: 'Run a TestCase subclass, a single test method, or all TestCase subclasses in a package. Returns pass/fail/error counts and failure messages.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'class_name' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'TestCase subclass name. Required unless package is given.'; yourself);
				at: 'selector' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Single test method selector. Omit to run all tests.'; yourself);
				at: 'package' put: (Dictionary new at: 'type' put: 'string'; at: 'description' put: 'Package name — runs all TestCase subclasses. Overrides class_name.'; yourself);
				yourself);
			at: 'required' put: #();
			yourself)
		handler: [ :args |
			| className selector package |
			className := args at: 'class_name' ifAbsent: [ nil ].
			selector := args at: 'selector' ifAbsent: [ nil ].
			package := args at: 'package' ifAbsent: [ nil ].
			package
				ifNotNil: [ MCPPharoTools runTestsInPackage: package ]
				ifNil: [
					className
						ifNil: [ 'Error: provide class_name or package' ]
						ifNotNil: [ MCPPharoTools runTestsForClass: className selector: selector ] ] ]
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

{ #category : 'running' }
MCPPharoTools class >> searchSourceFor: pattern inClass: className caseSensitive: caseSensitive [
	| cls methods |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	methods := cls methods , cls class methods.
	^ self searchSource: pattern inMethods: methods caseSensitive: caseSensitive
]

{ #category : 'running' }
MCPPharoTools class >> searchSourceFor: pattern inPackage: packageName caseSensitive: caseSensitive [
	| pkg methods |
	pkg := Smalltalk packageOrganizer packageNamed: packageName ifAbsent: [ ^ 'Error: package not found: ' , packageName ].
	methods := pkg classes flatCollect: [ :cls | cls methods , cls class methods ].
	^ self searchSource: pattern inMethods: methods caseSensitive: caseSensitive
]

{ #category : 'tools' }
MCPPharoTools class >> searchSourceTool [
	^ MCPTool
		name: 'search_source'
		description: 'Search method source code for a text pattern across a class or package. Returns matching method names with the first matching line. Use for finding string literals, comments, or any text that find_implementors/find_senders cannot locate.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'pattern' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Text to search for in method source code';
					yourself);
				at: 'class_name' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Search methods of this class (instance + class side). Required unless package given.';
					yourself);
				at: 'package' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Search all methods in this package. Overrides class_name.';
					yourself);
				at: 'case_sensitive' put: (Dictionary new
					at: 'type' put: 'boolean';
					at: 'description' put: 'Case-sensitive match. Defaults to false.';
					yourself);
				yourself);
			at: 'required' put: #('pattern');
			yourself)
		handler: [ :args |
			| pattern className package cs |
			pattern := args at: 'pattern' ifAbsent: [ nil ].
			pattern ifNil: [ 'Error: pattern is required' ] ifNotNil: [
				className := args at: 'class_name' ifAbsent: [ nil ].
				package := args at: 'package' ifAbsent: [ nil ].
				cs := args at: 'case_sensitive' ifAbsent: [ false ].
				package
					ifNotNil: [ self searchSourceFor: pattern inPackage: package caseSensitive: cs ]
					ifNil: [
						className
							ifNotNil: [ self searchSourceFor: pattern inClass: className caseSensitive: cs ]
							ifNil: [ 'Error: provide class_name or package' ] ] ] ]
]

{ #category : 'running' }
MCPPharoTools class >> setClassComment: comment onClass: className [
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'Error: class not found: ' , className ].
	cls comment: comment.
	^ 'Comment set on: ' , className
]

{ #category : 'private' }
MCPPharoTools class >> writeMatchEntry: m norm: norm to: s [
	| matchLine |
	s << m methodClass name; << ' >> #'; << m selector; nextPut: Character lf.
	matchLine := m sourceCode lines
		detect: [ :l | l asLowercase includesSubstring: norm ]
		ifNone: [ nil ].
	matchLine ifNotNil: [ s << '  '; << matchLine trimmed; nextPut: Character lf ]
]
