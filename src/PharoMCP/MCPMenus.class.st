Class {
	#name : 'MCPMenus',
	#superclass : 'Object',
	#category : 'PharoMCP',
	#package : 'PharoMCP'
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
