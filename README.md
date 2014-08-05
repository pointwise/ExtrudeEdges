# ExtrudeEdges
A Glyph script that extrudes the edges of a selected quilt along a specified vector into a single, closed model for more robust trimming operations.

## Selection
This script allows the user to extrude the edges of a selected quilt in order to create a "cookie cutter" type model for problematic trimming operations when the surface to be trimmed and the trimming surface are nearly co-planar with a poorly defined intersection.

When the script is run, a GUI appears that prompts the user to specify a normal vector and a distance. After specifying those two values, the user should click the "Select" button and choose the quilt that is to be used to define the shape of the cutter. After selecting the desired quilt, a single "cookie cutter" model will be automatically created by extruding the edges of the selected quilt in both directions along the distance and direction specified. Note that the value for the Normal Vector 

The "Cancel" button will exit the script without making any changes.

All entities created by the script are placed in Layer 999 by default. The visibility of this layer will be enabled when the script completes.

![ScriptImage](https://raw.github.com/pointwise/ExtrudeEdges/master/GUI.png)

## Disclaimer
Scripts are freely provided. They are not supported products of
Pointwise, Inc. Some scripts have been written and contributed by third
parties outside of Pointwise's control.

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, WITH REGARD TO THESE SCRIPTS. TO THE MAXIMUM EXTENT PERMITTED
BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY
FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS
INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR
INABILITY TO USE THESE SCRIPTS EVEN IF POINTWISE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE FAULT OR NEGLIGENCE OF
POINTWISE.
	 

