Class {
	#name : 'BaselineOfPharoMCP',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPharoMCP',
	#package : 'BaselineOfPharoMCP'
}

{ #category : 'baseline' }
BaselineOfPharoMCP >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec baseline: 'NeoJSON'
			with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
		spec
			package: 'PharoMCP'
				with: [ spec requires: #('NeoJSON') ];
			package: 'PharoMCP-Tests'
				with: [ spec requires: #('PharoMCP') ]
	]
]
