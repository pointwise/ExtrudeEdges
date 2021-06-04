# ExtrudeEdges
Copyright 2021 Cadence Design Systems, Inc. All rights reserved worldwide.

A Glyph script that extrudes the edges of a selected quilt along a specified vector into a single, closed model for more robust trimming operations.

## Selection
This script allows the user to extrude the edges of a selected quilt in order to create a "cookie cutter" type model for problematic trimming operations when the surface to be trimmed and the trimming surface are nearly co-planar with a poorly defined intersection.

When the script is run, a GUI appears that prompts the user to specify a normal vector and a distance. After specifying those two values, the user should click the "Select" button and choose the quilt that is to be used to define the shape of the cutter. After selecting the desired quilt, a single "cookie cutter" model will be automatically created by extruding the edges of the selected quilt in both directions along the distance and direction specified. Note that the value for the Normal Vector must contain three components which will be normalized, and the value for the Distance distance must be greater than zero.

The "Cancel" button will exit the script without making any changes.

All entities created by the script are placed in Layer 999 by default. The visibility of this layer will be enabled when the script completes.

![ScriptImage](https://raw.github.com/pointwise/ExtrudeEdges/master/GUI.png)

## Disclaimer
This file is licensed under the Cadence Public License Version 1.0 (the "License"), a copy of which is found in the LICENSE file, and is distributed "AS IS." 
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE. 
Please see the License for the full text of applicable terms.
	 

