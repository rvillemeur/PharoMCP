"
The run_tests tool: runs one test method, one TestCase subclass, or every TestCase subclass of a package, and answers counts with one entry per failure and per error. It declares an output schema, so a client reads the counts as data and not only the summary line.
"
Class {
	#name : 'MCPRunTestsTool',
	#superclass : 'MCPTool',
	#category : 'PharoMCP-Tools',
	#package : 'PharoMCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPRunTestsTool >> annotations [

	^ self additiveHints
]

{ #category : 'accessing' }
MCPRunTestsTool >> description [

	^ 'Run a TestCase subclass, a single test method, or all TestCase subclasses in a package. Returns pass/fail/error counts and failure messages.'
]

{ #category : 'calling' }
MCPRunTestsTool >> execute: arguments [

	^ (arguments at: 'package' ifAbsent: [ nil ])
		ifNotNil: [ :package | MCPPharoTools runTestsInPackage: package ]
		ifNil: [
			(arguments at: 'class_name' ifAbsent: [ nil ])
				ifNil: [ MCPToolError signal: 'provide class_name or package' ]
				ifNotNil: [ :className |
					MCPPharoTools
						runTestsForClass: className
						selector: (arguments at: 'selector' ifAbsent: [ nil ]) ] ]
]

{ #category : 'accessing' }
MCPRunTestsTool >> inputSchema [

	^ self
		schemaWithProperties: {
			'class_name' -> (self schemaPropertyOfType: 'string' describedAs: 'TestCase subclass name. Required unless package is given.').
			'selector' -> (self schemaPropertyOfType: 'string' describedAs: 'Single test method selector. Omit to run all tests.').
			'package' -> (self schemaPropertyOfType: 'string' describedAs: 'Package name — runs all TestCase subclasses. Overrides class_name.') }
		required: #()
]

{ #category : 'accessing' }
MCPRunTestsTool >> name [

	^ 'run_tests'
]

{ #category : 'accessing' }
MCPRunTestsTool >> outputSchema [

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

{ #category : 'accessing' }
MCPRunTestsTool >> title [

	^ 'Run tests'
]
