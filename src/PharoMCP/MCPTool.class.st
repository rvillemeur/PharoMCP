Class {
	#name : 'MCPTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'inputSchema',
		'handler'
	],
	#category : 'PharoMCP-Core',
	#package : 'PharoMCP',
	#tag : 'Core'
}

{ #category : 'instance creation' }
MCPTool class >> name: aName description: aDescription schema: aSchema handler: aBlock [
	^ self new
		name: aName;
		description: aDescription;
		inputSchema: aSchema;
		handler: aBlock;
		yourself
]

{ #category : 'converting' }
MCPTool >> asDictionary [
	^ Dictionary new
		at: 'name' put: name;
		at: 'description' put: description;
		at: 'inputSchema' put: inputSchema;
		yourself
]

{ #category : 'executing' }
MCPTool >> call: arguments [
	^ handler value: arguments
]

{ #category : 'accessing' }
MCPTool >> description [
	^ description
]

{ #category : 'accessing' }
MCPTool >> description: aString [
	description := aString
]

{ #category : 'accessing' }
MCPTool >> handler [
	^ handler
]

{ #category : 'accessing' }
MCPTool >> handler: aBlock [
	handler := aBlock
]

{ #category : 'accessing' }
MCPTool >> inputSchema [
	^ inputSchema
]

{ #category : 'accessing' }
MCPTool >> inputSchema: aDictionary [
	inputSchema := aDictionary
]

{ #category : 'accessing' }
MCPTool >> name [
	^ name
]

{ #category : 'accessing' }
MCPTool >> name: aString [
	name := aString
]
