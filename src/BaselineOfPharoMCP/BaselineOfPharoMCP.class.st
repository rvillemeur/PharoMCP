Class {
	#name : #BaselineOfPharoMCP,
	#superclass : #BaselineOf,
	#category : #'BaselineOfPharoMCP'
}

{ #category : #baseline }
BaselineOfPharoMCP >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'PharoMCP';
			package: 'PharoMCP-Tests'
				with: [ spec requires: #('PharoMCP') ]
	]
]
