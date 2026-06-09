"
Provides Pharo world-menu entries for opening the PharoMCP server presenter.
"
Class {
	#name : 'MCPMenus',
	#superclass : 'Object',
	#category : 'PharoMCP-UI',
	#package : 'PharoMCP',
	#tag : 'UI'
}

{ #category : 'menu' }
MCPMenus class >> buildWorldMenu: aBuilder [
	<worldMenu>
	(aBuilder item: #PharoMCPServer)
		parent: #Tools;
		label: 'MCP Server';
		action: [ MCPServerPresenter open ];
		iconName: #glamorousTable;
		order: 40;
		yourself
]
