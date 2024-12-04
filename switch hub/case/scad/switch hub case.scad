$fn=128;

PCBThickness=1.6;
outset=0.5;  //how much to shrink (or expand) the PCB cutout. 
totalHeight=5.5;
wallThickness=2;

xiaoPCBThickness=1;
jackDiameter=5.5;

pegDiameter=1.6;
pegLength=2.5;
socketDiameter=3.8;
fit=0.3;

overlap=1;  //how much the upper half clamshells with the bottom
overlapFit=0.2;  //how much gap between the inner and outer clamshells
overlapClasp=0.2;
overlapClaspFitPct=0.45;

base=true;
generateInternalSockets=false;

difference(){
    union(){
        difference(){
            
            //generate case shape
            minkowski(){
                translate([0,0,wallThickness]){
                    PCB(totalHeight,false,outset);
                }
                sphere(wallThickness);
            }
            
            if(base){
                //remove top half
                translate([0,0,wallThickness+totalHeight/2+75]){
                    cube(150,true);
                }
            }else{
                //remove bottom half
                translate([0,0,wallThickness+totalHeight/2-75]){
                    cube(150,true);
                }
            }
            
        }
        
        if(!base){
            //add lid clamshell
            translate([0,0,wallThickness+totalHeight/2-overlap]){
                minkowski(){
                    PCB(0.0001,false,outset);
                    cylinder(r=wallThickness/2-overlapFit/2,h=overlap);
                }
                minkowski(){
                    PCB(0.0001,false,outset);
                    cylinder(r=wallThickness/2-overlapFit/2 + overlapClasp,h=overlap*overlapClaspFitPct);
                }
            }
        }
    }

    if(base){
        //cut base clamshell
        translate([0,0,wallThickness+totalHeight/2-overlap]){
            minkowski(){
                PCB(0.0001,false,outset);
                cylinder(r=wallThickness/2 + overlapFit/2, h=overlap*(1-overlapClaspFitPct));
            }
            minkowski(){
                PCB(0.0001,false,outset);
                cylinder(r=wallThickness/2 + overlapFit/2 - overlapClasp, h=overlap*2);
            }
        }
    }
        
    //PCB cutout
    translate([0,0,wallThickness-PCBThickness]){
        PCB(PCBThickness+totalHeight,false,outset);
    }

    //USB socket
    translate([25,50+10,wallThickness+xiaoPCBThickness]){
        rotate([90,0,0]){
            USBCSocket();
        }
    }


    //jack cutouts
    jackPosition(2,42,wallThickness+totalHeight/2,90);
    jackPosition(2,30,wallThickness+totalHeight/2,90);
    jackPosition(3.75,16.19,wallThickness+totalHeight/2,112.5);
    jackPosition(16.2,3.75,wallThickness+totalHeight/2,157.5);
    jackPosition(33.8,3.75,wallThickness+totalHeight/2,202.5);
    jackPosition(46.25,16.19,wallThickness+totalHeight/2,247.5);
    jackPosition(48.07,30.1,wallThickness+totalHeight/2,270);
    jackPosition(48.07,41.94,wallThickness+totalHeight/2,270);

}


if(generateInternalSockets){
    if(base){
        //generate base pegs
        translate([25,5,0])cylinder(d=pegDiameter,h=wallThickness+pegLength);
        translate([13.5,36,0])cylinder(d=pegDiameter,h=wallThickness+pegLength);
        translate([36.5,36,0])cylinder(d=pegDiameter,h=wallThickness+pegLength);
    }else{
        //generate top sockets
        translate([25,5,wallThickness]){
            difference(){
                cylinder(d=socketDiameter,h=totalHeight);
                cylinder(d=pegDiameter+fit,h=totalHeight);
            }
        }
        translate([13.5,36,wallThickness]){
            difference(){
                cylinder(d=socketDiameter,h=totalHeight);
                cylinder(d=pegDiameter+fit,h=totalHeight);
            }
        }
        translate([36.5,36,wallThickness]){
            difference(){
                cylinder(d=socketDiameter,h=totalHeight);
                cylinder(d=pegDiameter+fit,h=totalHeight);
            }
        }
        
        //and vanes
        translate([24.6,2-outset,wallThickness])cube([0.8,2,5]);
        translate([wallThickness-outset,35.6,wallThickness])cube([11,0.8,5]);
        translate([50-wallThickness-11+outset,35.6,wallThickness])cube([11,0.8,5]);
    }
}



module jackPosition(x=0,y=0,z=0,r=0){
    translate([x,y,z]){
        rotate([-90,0,r]){
            translate([0,0,-1]){
                cylinder(d=jackDiameter,h=10);
            }
        }
    }
}

module USBCSocket(length=20){  //reference size for USB-C socket
    width=8.94;
    height=3.36;
    rad=(width-6.69)/2;
    translate([-6.69/2,(height-rad)/2,0]){
        linear_extrude(length){
            minkowski(){
                square([width-rad*2,height-rad*2],false);
                circle(r=rad);
            }
        }
    }
}


module PCB(thickness=1.6, holes=true, outset=0.3){
    linear_extrude(thickness){
    difference(){
        union(){
            translate([25,25,0]){
                circle(23+outset);
            }
            translate([46,46,0]){
                circle(2+outset);
            }
            translate([4,46,0]){
                circle(2+outset);
            }
            translate([2-outset,25,0]){
                square([46+outset*2,21],false);
            }
            translate([4,25-outset,0]){
                square([42,23+outset*2],false);
            }
        }
        //PCB holes
        if(holes){
            translate([13.5,36,0]){
                circle(1);
            }
            translate([36.5,36,0]){
                circle(1);
            }
            translate([25,5,0]){
                circle(1);
            }
        }
    }
}
}