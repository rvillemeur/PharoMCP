Class {
	#name : 'BaselineOfPharoMCP',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPharoMCP',
	#package : 'BaselineOfPharoMCP'
}

{ #category : 'baselines' }
BaselineOfPharoMCP >> baseline: spec [

	"'default' is the server alone: a client loading PharoMCP to drive an image needs neither
	 the tests nor the examples. The examples package requires PharoMCP because every example
	 builds an object of it, and the tests require the examples because the test classes read
	 them. 'dev' adds MuTalk, pinned to a release tag rather than master so a mutation score
	 measured today can be measured again against the same mutant operators."

	<baseline>
	spec for: #common do: [
		spec baseline: 'NeoJSON'
			with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
		spec baseline: 'MuTalk'
			with: [ spec repository: 'github://pharo-contributions/mutalk:v3.0.8' ].
		spec
			package: 'PharoMCP'
				with: [ spec requires: #('NeoJSON') ];
			package: 'PharoMCP-Examples'
				with: [ spec requires: #('PharoMCP') ];
			package: 'PharoMCP-Tests'
				with: [ spec requires: #('PharoMCP' 'PharoMCP-Examples') ].
		spec
			group: 'default' with: #('PharoMCP');
			group: 'examples' with: #('PharoMCP-Examples');
			group: 'tests' with: #('PharoMCP-Tests');
			group: 'dev' with: #('PharoMCP-Tests' 'MuTalk') ]
]
