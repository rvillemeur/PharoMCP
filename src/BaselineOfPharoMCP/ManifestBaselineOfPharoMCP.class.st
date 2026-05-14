"
Small MCP server developed for Pharo

To load it from local repositoriesDo: 

```st
Metacello new                                                                   
      baseline: 'PharoMCP';                                                    
      repository: 'tonel:///home/renaud/devzone/sources/PharoMCP/src';          
      load.  
```
To register it in Iceberg if loaded manually:

```st
  IceRepository register: (IceRepositoryCreator new
      location: '/home/renaud/devzone/sources/PharoMCP' asFileReference;
      createRepository).
```
"
Class {
	#name : 'ManifestBaselineOfPharoMCP',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfPharoMCP-Manifest',
	#package : 'BaselineOfPharoMCP',
	#tag : 'Manifest'
}
