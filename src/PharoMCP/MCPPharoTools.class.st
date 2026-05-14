Class {
	#name : #MCPPharoTools,
	#superclass : #Object,
	#category : #'PharoMCP-Core'
}

{ #category : #registration }
MCPPharoTools class >> registerToolsWith: aProcessor [
	self allTools do: [ :tool | aProcessor registerTool: tool ]
]

{ #category : #tools }
MCPPharoTools class >> allTools [
	^ Array
		with: self evaluateTool
		with: self listClassesTool
		with: self classDefinitionTool
		with: self methodSourceTool
		with: self listMethodsTool
]

{ #category : #tools }
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
			| code result |
			code := args at: 'code' ifAbsent: [ ^ 'Error: missing code argument' ].
			result := [ Compiler evaluate: code ]
				on: Error
				do: [ :e | ^ 'Error: ' , e messageText ].
			result printString ]
]

{ #category : #tools }
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
			| pattern classes |
			pattern := args at: 'pattern' ifAbsent: [ '' ].
			pattern isEmpty ifTrue: [ ^ 'Provide a non-empty pattern. The image contains thousands of classes.' ].
			classes := Smalltalk globals allClasses
				select: [ :c | c name asLowercase includesSubstring: pattern asLowercase ].
			classes isEmpty
				ifTrue: [ 'No classes found matching: ' , pattern ]
				ifFalse: [
					| sorted limited header |
					sorted := classes asSortedCollection: [ :a :b | a name < b name ].
					limited := sorted size > 50
						ifTrue: [ sorted first: 50 ]
						ifFalse: [ sorted ].
					header := sorted size > 50
						ifTrue: [ 'Found ' , sorted size printString , ' classes (showing first 50):' , String lf ]
						ifFalse: [ '' ].
					header , (String streamContents: [ :s |
						limited do: [ :c | s nextPutAll: c name ] separatedBy: [ s nextPut: Character lf ] ]) ] ]
]

{ #category : #tools }
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
			| className class |
			className := args at: 'className' ifAbsent: [ ^ 'Error: missing className' ].
			class := Smalltalk globals at: className asSymbol ifAbsent: [
				^ 'Error: class not found: ' , className ].
			class definition ]
]

{ #category : #tools }
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
			| className methodName class method |
			className := args at: 'className' ifAbsent: [ ^ 'Error: missing className' ].
			methodName := args at: 'methodName' ifAbsent: [ ^ 'Error: missing methodName' ].
			class := Smalltalk globals at: className asSymbol ifAbsent: [
				^ 'Error: class not found: ' , className ].
			(args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
				ifTrue: [ class := class class ].
			method := class methodDictionary
				at: methodName asSymbol
				ifAbsent: [ ^ 'Error: method not found: ' , methodName , ' in ' , class name ].
			method sourceCode ]
]

{ #category : #tools }
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
			| className class selectors |
			className := args at: 'className' ifAbsent: [ ^ 'Error: missing className' ].
			class := Smalltalk globals at: className asSymbol ifAbsent: [
				^ 'Error: class not found: ' , className ].
			(args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
				ifTrue: [ class := class class ].
			selectors := class methodDictionary keys asSortedCollection.
			selectors isEmpty
				ifTrue: [ 'No methods defined on ' , class name ]
				ifFalse: [
					String streamContents: [ :s |
						selectors do: [ :sel | s nextPutAll: sel ] separatedBy: [ s nextPut: Character lf ] ] ] ]
]
