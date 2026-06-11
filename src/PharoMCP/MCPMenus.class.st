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
	(aBuilder item: #PharoMCP)
		order: 20.0;
		with: [ (aBuilder item: #PharoMCPServer)
		parent: #PharoMCP;
		label: 'MCP Server';
		action: [ MCPServerPresenter open ];
		iconName: #glamorousTable;
		order: 0;
		help: 'launch Pharo MCP server'.]
]
