# Quick Switch



This repo contains all files necessary to produce an ultra-cheap accessibility switch.



There have been 3 versions so far:

* mk 1 used multiple placed switches to achieve reliable actuation when pressed anywhere, but early tests by users found the tactile response and multiple "clicks" unpleasant. Files for this version are not included anywhere.
* mk 2 just used one centre switch in a 12x12 SMD package, and improved upon various physical aspects of the design.
* mk 3 improves more reliably actuates when pressed anywhere, and is less breakable.



### Folders



**Designs** - contains rough sketches of each version.

**PCB** - contains schematics and PCB production files for the current version. Gerbers and BOM are set up for JLCPCB.

**SCAD** - contains openSCAD files for generating the buttons. The "quick switch mk3.scad" default settings will generate the default, current version.

**STL** - contains STL files for the current version.



### How to make



Order or otherwise produce the PCBs, using the gerber files in the "PCB" directory. You can have these assembled in the factory, or solder on the parts yourself. The PCB is exceedingly simple and could be milled. I have chosen to use a jack socket to reduce work stripping and soldering cables, but a cable could be soldered direct to the board instead.



3D print the top and bottom parts from the "STL" directory. You will need to print the top upside down.



When you have all 3 parts, drop the PCB into its slot in the base, and align and click in the top.



You can use a mono (or stereo) jack cable to connect the switch to your device.



### Roadmap



* Refactor, improve and modularise SCAD file
* Support generating PCB outlines and component positions from SCAD file, so more customisable designs are possible.
* Add support for directly soldering wire to board 
* Further improve durability: perhaps by adding tougher clasps or using a different system entirely.





