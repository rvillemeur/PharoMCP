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

{ #category : 'tools' }
MCPPharoTools class >> allTools [
	^ (OrderedCollection new
		add: self evaluateTool; add: self listClassesTool; add: self classDefinitionTool;
		add: self methodSourceTool; add: self listMethodsTool; add: self runTestsTool;
		add: self runCriticsTool; add: self findSendersTool; add: self findImplementorsTool;
		add: self listPackagesTool; add: self classHierarchyTool;
		yourself) asArray
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
	| class superchain subclasses |
	class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
	class isNil ifTrue: [ ^ 'Error: class not found: ' , className ].
	superchain := class allSuperclasses reversed.
	subclasses := class subclasses asSortedCollection: [ :a :b | a name < b name ].
	^ String streamContents: [ :s |
		s nextPutAll: 'Superclass chain:'; nextPut: Character lf.
		s nextPutAll: (((superchain collect: [ :c | c name ]) , (Array with: class name)) joinUsing: ' > ').
		s nextPut: Character lf; nextPut: Character lf.
		s nextPutAll: 'Direct subclasses (' , subclasses size printString , '):'; nextPut: Character lf.
		subclasses isEmpty
			ifTrue: [ s nextPutAll: '  (none)' ]
			ifFalse: [ subclasses do: [ :c | s nextPutAll: '  ' , c name; nextPut: Character lf ] ] ]
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
	(ReCriticEngine critiquesOf: aClass) do: [:c | critiques add: c].
	(ReCriticEngine critiquesOf: aClass class) do: [:c | critiques add: c].
	aClass methodDictionary values do: [:m |
		(ReCriticEngine critiquesOf: m) do: [:c | critiques add: c] ].
	aClass class methodDictionary values do: [:m |
		(ReCriticEngine critiquesOf: m) do: [:c | critiques add: c] ].
	^ critiques
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
		s nextPutAll: results size printString , ' implementors of #' , selector; nextPut: Character lf.
		names do: [ :n | s nextPutAll: n; nextPut: Character lf ] ]
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
	sorted := (results collect: [ :m | m methodClass name , ' >> #' , m selector]) asSortedCollection.
	limited := sorted size > 100 ifTrue: [ sorted first: 100 ] ifFalse: [ sorted ].
	^ String streamContents: [ :s |
		sorted size > 100 ifTrue: [
			s nextPutAll: 'Showing first 100 of ' , sorted size printString , ' senders';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :line | s nextPutAll: line; nextPut: Character lf ] ]
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
MCPPharoTools class >> formatCritiques: critiques forName: name [
	| limited |
	critiques isEmpty ifTrue: [ ^ 'No critiques found for: ' , name ].
	limited := critiques size > 200
		ifTrue: [ critiques first: 200 ]
		ifFalse: [ critiques ].
	^ String streamContents: [ :s |
		critiques size > 200 ifTrue: [
			s nextPutAll: 'Showing first 200 of ' , critiques size printString , ' critiques';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :c |
			[ s nextPutAll: '[' , c rule class name , '] ' , c title.
			c sourceAnchor ifNotNil: [ :a |
				[s nextPutAll: ' (' , a entity printString , ')'] on: Error do: [ :e | ] ].
			s nextPut: Character lf ] on: Error do: [ :e | ] ] ]
]

{ #category : 'private' }
MCPPharoTools class >> formatPackageSummary: aPackage [
	| tc |
	tc := (aPackage classes select: [ :c | c inheritsFrom: TestCase ]) size.
	^ String streamContents: [ :s |
		s nextPutAll: aPackage name , ' (' , aPackage classes size printString , ' classes'.
		tc > 0 ifTrue: [ s nextPutAll: ', ' , tc printString , ' test classes' ].
		s nextPutAll: ')' ]
]

{ #category : 'running' }
MCPPharoTools class >> formatResult: result forName: name selector: selector [
	^ String streamContents: [ :s |
		selector
			ifNil: [ s nextPutAll: 'Ran ' , result runCount printString , ' tests in ' , name; nextPut: Character lf ]
			ifNotNil: [ :sel | s nextPutAll: 'Ran ' , name , ' >> ' , sel; nextPut: Character lf ].
		s nextPutAll: result passedCount printString , ' passed'; nextPut: Character lf.
		s nextPutAll: result unexpectedFailureCount printString , ' failed'; nextPut: Character lf.
		s nextPutAll: result unexpectedErrorCount printString , ' errored'; nextPut: Character lf.
		result failureMessages ifNotEmpty: [
			s nextPut: Character lf; nextPutAll: '--- Failures ---'; nextPut: Character lf.
			result failureMessages keysAndValuesDo: [ :sel :msg |
				s nextPutAll: sel; nextPut: Character lf; nextPutAll: msg; nextPut: Character lf; nextPut: Character lf ] ].
		result errorMessages ifNotEmpty: [
			s nextPut: Character lf; nextPutAll: '--- Errors ---'; nextPut: Character lf.
			result errorMessages keysAndValuesDo: [ :sel :msg |
				s nextPutAll: sel; nextPut: Character lf; nextPutAll: msg; nextPut: Character lf; nextPut: Character lf ] ] ]
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
		description: 'List all method selectors defined on a class. Use side "class" for class-side methods.'
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
			args at: 'className'
				ifPresent: [ :className |
					| class side selectors |
					class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
					class isNil
						ifTrue: [ 'Error: class not found: ' , className ]
						ifFalse: [
							side := (args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
								ifTrue: [ class class ]
								ifFalse: [ class ].
							selectors := side methodDictionary keys asSortedCollection.
							selectors isEmpty
								ifTrue: [ 'No methods defined on ' , class name ]
								ifFalse: [
									String streamContents: [ :s |
										selectors do: [ :sel | s nextPutAll: sel ] separatedBy: [ s nextPut: Character lf ] ] ] ] ]
				ifAbsent: [ 'Error: missing className' ] ]
]

{ #category : 'private' }
MCPPharoTools class >> listPackagesMatching: pattern [
	| allPkgs filtered sorted limited |
	allPkgs := Smalltalk packageOrganizer packages.
	filtered := (pattern isNil or: [ pattern isEmpty ])
		ifTrue: [ allPkgs ]
		ifFalse: [ allPkgs select: [ :p | p name asLowercase includesSubstring: pattern asLowercase ] ].
	filtered isEmpty ifTrue: [ ^ 'No packages found matching: ' , pattern ].
	sorted := filtered asSortedCollection: [ :a :b | a name < b name ].
	limited := sorted size > 200 ifTrue: [ sorted first: 200 ] ifFalse: [ sorted ].
	^ String streamContents: [ :s |
		sorted size > 200 ifTrue: [
			s nextPutAll: 'Showing first 200 of ' , sorted size printString , ' packages';
			nextPut: Character lf; nextPut: Character lf ].
		limited do: [ :p | s nextPutAll: (MCPPharoTools formatPackageSummary: p); nextPut: Character lf ] ]
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
		description: 'Get the source code of a method. Use side "class" for class-side methods, "instance" for instance-side methods.'
		schema: (Dictionary new
			at: 'type' put: 'object';
			at: 'properties' put: (Dictionary new
				at: 'className' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Name of the class';
					yourself);
				at: 'methodName' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'description' put: 'Selector of the method (e.g. "add:" or "printOn:")';
					yourself);
				at: 'side' put: (Dictionary new
					at: 'type' put: 'string';
					at: 'enum' put: #('instance' 'class');
					at: 'description' put: 'Whether to look on the instance side or class side. Defaults to instance.';
					yourself);
				yourself);
			at: 'required' put: #('className' 'methodName');
			yourself)
		handler: [ :args |
			args at: 'className'
				ifPresent: [ :className |
					args at: 'methodName'
						ifPresent: [ :methodName |
							| class side |
							class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
							class isNil
								ifTrue: [ 'Error: class not found: ' , className ]
								ifFalse: [
									side := (args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
										ifTrue: [ class class ]
										ifFalse: [ class ].
									side methodDictionary
										at: methodName asSymbol
										ifPresent: [ :method | method sourceCode ]
										ifAbsent: [ 'Error: method not found: ' , methodName , ' in ' , class name ] ] ]
						ifAbsent: [ 'Error: missing methodName' ] ]
				ifAbsent: [ 'Error: missing className' ] ]
]

{ #category : 'registration' }
MCPPharoTools class >> registerToolsWith: aProcessor [
	self allTools do: [ :tool | aProcessor registerTool: tool ]
]

{ #category : 'running' }
MCPPharoTools class >> runCriticsOnClass: className [
	| class critiques |
	class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
	class isNil ifTrue: [ ^ 'Error: class not found: ' , className ].
	critiques := self collectCritiquesForClass: class.
	^ self formatCritiques: critiques forName: className
]

{ #category : 'running' }
MCPPharoTools class >> runCriticsOnPackage: packageName [
	| pkg critiques |
	pkg := Smalltalk packageOrganizer packageNamed: packageName ifAbsent: [ nil ].
	pkg isNil ifTrue: [ ^ 'Error: package not found: ' , packageName ].
	critiques := OrderedCollection new.
	pkg classes do: [ :cls |
		(self collectCritiquesForClass: cls) do: [ :c | critiques add: c ] ].
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
	| class suite result |
	class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
	class isNil ifTrue: [ ^ 'Error: class not found: ' , className ].
	(class inheritsFrom: TestCase) ifFalse: [
		^ 'Error: ' , className , ' is not a TestCase subclass' ].
	suite := selector
		ifNil: [ class suite ]
		ifNotNil: [ :sel |
			TestSuite new
				addTest: (class selector: sel asSymbol);
				yourself ].
	result := MCPTestResult new.
	suite run: result.
	^ self formatResult: result forName: className selector: selector
]

{ #category : 'running' }
MCPPharoTools class >> runTestsInPackage: packageName [
	| pkg classes suite result |
	pkg := Smalltalk packageOrganizer packageNamed: packageName ifAbsent: [ nil ].
	pkg isNil ifTrue: [ ^ 'Error: package not found: ' , packageName ].
	classes := pkg classes select: [ :c | c inheritsFrom: TestCase ].
	classes isEmpty ifTrue: [ ^ 'Error: no TestCase subclasses in package: ' , packageName ].
	suite := TestSuite new.
	classes do: [ :c | c suite tests do: [ :t | suite addTest: t ] ].
	result := MCPTestResult new.
	suite run: result.
	^ self formatResult: result forName: packageName selector: nil
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
