/*
todo: 
- more frequent clasps 
- generate PCB from script (or at least outline and part positions)
*/


#include <BOSL2/std.scad>
$fn=256;

error=0.3;  //useful "fit" adjustment, for 3D printer error/fine tuning

pcbThickness=1.6;
pcbDiameter=50;

buttonSize=[15,12,5];   //size of tactile switch
buttonTravel=0.4;   //button travel distance
buttonClearance=[2,2,0]; //added clearance around button dimensions

pcbHeightOffset=2;  //required for a jack plug to fit (i.e. clearance from base)

jackHeight=5.1;       //height of jack socket component
jackPlugSize=6;     //radius of hole for jack plug (5mm)
jackClearance=buttonTravel*2;    //extra space above jack socket part

tallestComponent=jackHeight; //have to manually alter this for now

baseDiameter=76;
baseHoles = 6;
baseHoleDiameter=4;
baseThickness=2.5;
baseClaspWidth=15;  //in degrees
baseClaspGap=2;     //in degrees
baseClaspTravelGap=0.4; //in degrees
baseClasps=8;
baseClaspOffset=-90+180/baseClasps; //in degrees
screwMount=true;

claspAngleLength=1; //how many mm long clasp slope is
claspOverlap=0.8;   //clasp slope depth

wallThickness=1.2;    //thickness of walls around button

topTransitionLength=wallThickness*1.25;  //angled transition to top volume
topHeight=8;              //height of top section
topRounding=topHeight*.333; //rounded top radius
topFitError=0;

drawBase=true;             //render button base
drawTop=false;               //render button top
crossSection=false;         //see cross section
crossSectionAngle=-90+180/(baseClasps);      


//secondary variables
baseHeight=baseThickness+tallestComponent+pcbHeightOffset+pcbThickness;
e2=error*2;

difference(){
    union(){  //union for cross section
    
        //base part
        if(drawBase){   
            difference(){
                union(){
                    //clasped base sections
                    clasps(false,buttonTravel=buttonTravel*2,error=error);

                    //unclasped base sections
                    unclasps();

                    //remaining button base
                    if(screwMount)cylinder(d=baseDiameter,h=baseThickness);
                    difference(){
                        union(){
                            intersection(){
                                unclaspIntersection();
                                cylinder(d=pcbDiameter+(claspOverlap+wallThickness)*2,h=baseThickness+pcbHeightOffset+pcbThickness);
                            }
                            cylinder(d=pcbDiameter,h=baseThickness+pcbHeightOffset+pcbThickness);
                        }
                        translate([0,0,baseThickness+pcbHeightOffset])//cylinder(d=pcbDiameter+e2,h=pcbThickness);  //old circular PCB
                        linear_extrude(pcbThickness+0.01)
                        offset(error)import("PCB outline.svg");
                    }
                }
                
                //jack cutout
                translate([0,0,baseThickness+pcbHeightOffset+pcbThickness+jackPlugSize*.5]){
                    rotate([0,90,-90]){
                        union(){
                            cylinder(d=jackPlugSize+e2,h=100);
                            cuboid(size=[jackPlugSize+e2,jackPlugSize+error*2,100],anchor=RIGHT+BOTTOM);
                        }
                    }
                }
                
                //base holes
                if(screwMount){
                    r=(baseDiameter+(pcbDiameter+claspOverlap+wallThickness))/4;
                    for(a=[360/(baseHoles*4):360/baseHoles:360]){
                        translate([r*cos(a),r*sin(a),0]){
                            cylinder(d=baseHoleDiameter,h=100);
                        }
                    }
                }
            }
        }

        //top part
        if(drawTop){
            
            color([0,1,0,1])
            intersection(){
                difference(){
                    //main button body
                    translate([0,0,baseThickness+pcbHeightOffset+pcbThickness+buttonTravel])
                    union(){
                        cylinder(d=pcbDiameter+(claspOverlap-error)*2,h=tallestComponent); //main cylinder
                        translate([0,0,tallestComponent])
                        cylinder(d1=pcbDiameter+(claspOverlap-error)*2,d2=pcbDiameter+(claspOverlap+wallThickness)*2,h=topTransitionLength); //transition to top
                        translate([0,0,tallestComponent+topTransitionLength])
                        cyl(d=pcbDiameter+(claspOverlap+wallThickness)*2,h=topHeight,chamfer2=topRounding,teardrop=45, anchor=BOTTOM);  //top surface
                    }

                    translate([0,0,baseThickness+pcbHeightOffset+pcbThickness]){
                        //cutout cuboids for buttons
                        cuboid(buttonSize+buttonClearance,chamfer=1.5,except=BOTTOM,anchor=BOTTOM);
                        //cutouts for jack/wire connect
                        translate([0,-pcbDiameter/2-2,buttonTravel])
                        cuboid([7,16+2,jackHeight+jackClearance],anchor=FRONT+BOTTOM,rounding=jackClearance,edges=TOP);
                        translate([0,-pcbDiameter/2+1,buttonTravel])
                        cuboid([10,10,jackHeight+jackClearance],anchor=FRONT+BOTTOM,rounding=jackClearance,edges=TOP);
                    }
                    
                    clasps(true,buttonTravel*2,error=topFitError);
                }
                
                //slight angle on the bottom of button top to allow edge rotation
                translate([0,0,baseThickness+pcbHeightOffset+pcbThickness+buttonTravel])
                union(){
                    cyl(d1=0.001,d2=pcbDiameter+claspOverlap*2,h=buttonTravel,anchor=BOTTOM);
                    up(buttonTravel)
                    cyl(d=1000,h=1000,anchor=BOTTOM);
                }
            }
        }
    }
    
    if(crossSection){
        rotate([0,0,crossSectionAngle]){
            cuboid([1000,1000,1000],anchor=FRONT+BOTTOM);
        }
    }
}


//"renderTravel" is for rendering the clasp cutouts on the buttons, as opposed to the normal clasps
module clasps(renderTravel=false,buttonTravel=0.8,error=0.3){
    intersection(){
        difference(){
                    
            if(renderTravel){
                cylinder(d=pcbDiameter+(claspOverlap+wallThickness)*2,h=baseHeight+buttonTravel);
            }else{
                cylinder(d=pcbDiameter+(claspOverlap+wallThickness)*2,h=baseHeight);
            }
            
            if(renderTravel){
                translate([0,0,baseHeight-claspAngleLength+buttonTravel])
                cylinder(d1=pcbDiameter-error, d2=pcbDiameter+claspOverlap*2-error,h=claspAngleLength);
                translate([0,0,baseHeight-claspAngleLength])
                cylinder(d=pcbDiameter-error,h=buttonTravel);
            }else{
                translate([0,0,baseHeight-claspAngleLength])
                cylinder(d1=pcbDiameter, d2=pcbDiameter+claspOverlap*2,h=claspAngleLength);
            }
            
            if(renderTravel){
                translate([0,0,baseHeight-claspAngleLength*2])
                cylinder(d1=pcbDiameter+claspOverlap*2-error, d2=pcbDiameter-error,h=claspAngleLength);
            }else{
                translate([0,0,baseHeight-claspAngleLength*2])
                cylinder(d1=pcbDiameter+claspOverlap*2, d2=pcbDiameter,h=claspAngleLength);
            }
           
            cyl(d=pcbDiameter+claspOverlap*2,h=baseHeight-claspAngleLength*2,anchor=BOTTOM);
            
            
        }
        
        if(renderTravel){
            for(a=[baseClaspOffset:360/baseClasps:360+baseClaspOffset]){
                a1=a-baseClaspWidth*.5+baseClaspGap*.5-baseClaspTravelGap;
                a2=a+baseClaspWidth*.5-baseClaspGap*.5+baseClaspTravelGap;
                linear_extrude(100)
                polygon([
                [0,0],
                [100*cos(a1),100*sin(a1)],
                [100*cos(a2),100*sin(a2)]
                ]);
            }
        }else{
            for(a=[baseClaspOffset:360/baseClasps:360+baseClaspOffset]){
                linear_extrude(100)
                polygon([
                [0,0],
                [100*cos(a-baseClaspWidth*.5+baseClaspGap*.5),100*sin(a-baseClaspWidth*.5+baseClaspGap*.5)],
                [100*cos(a+baseClaspWidth*.5-baseClaspGap*.5),100*sin(a+baseClaspWidth*.5-baseClaspGap*.5)]
                ]);
            }
        }
    }
}

//unclasps are button base edge structure that is not clasps
module unclasps(){
    difference(){
        intersection(){
            difference(){
                cylinder(d=pcbDiameter+(claspOverlap+wallThickness)*2,h=baseHeight);
                
                cyl(d=pcbDiameter+claspOverlap*2,h=baseHeight,anchor=BOTTOM);
            }

            unclaspIntersection();
        }
    }
}

module unclaspIntersection(){
    for(a=[baseClaspOffset:360/baseClasps:360+baseClaspOffset]){
        linear_extrude(100)
        polygon([
        [0,0],
        [100*cos(a+baseClaspWidth*.5+baseClaspGap*.5),100*sin(a+baseClaspWidth*.5+baseClaspGap*.5)],
        [100*cos(a+360/baseClasps-baseClaspWidth*.5-baseClaspGap*.5),100*sin(a+360/baseClasps-baseClaspWidth*.5-baseClaspGap*.5)]
        ]);
    }
}