// rover.ks
// Written by KK4TEE
// License: GPLv3
//
// This program provides stability assistance
// for manually driven rovers

set speedlimit to 35. //All speeds are in m/s
lock turnlimit to min(1, 8 / GROUNDSPEED). //Scale the 
                   //turning radius based on current speed


set looptime to 0.01.
set loopEndTime to TIME:SECONDS.
set eWheelThrottle to 0. // Error between target speed and actual speed
set iWheelThrottle to 0. // Accumulated speed error
set wtVAL to 0. //Wheel Throttle Value
set kTurn to 0. //Wheel turn value.
set targetspeed to 0. //Cruise control starting speed
set targetHeading to 90. //Used for autopilot steering
set NORTHPOLE to latlng( 90, 0). //Reference heading


clearscreen.
sas off.
rcs off.
lights on.
lock throttle to 0.
set runmode to 0.
on ag10 { //When the 0 key is pressed:
    // End the program
    set runmode to -1.
    }
    
until runmode = -1 {

    //Update the compass:
    // I want the heading to match the navball 
    // and be out of 360' instead of +/-180'
    // I do this by judging the heading relative
    // to a latlng set to the north pole
    if northPole:bearing <= 0 {
        set cHeading to ABS(northPole:bearing).
        }
    else {
        set cHeading to (180 - northPole:bearing) + 180.
        }

    if runmode = 0 { //Govern the rover 
    
        //Wheel Throttle:
        set targetspeed to targetspeed + 0.05 * SHIP:CONTROL:PILOTWHEELTHROTTLE.
        set targetspeed to max(-1, min( speedlimit, targetspeed)).
        
        if targetspeed > 0 { //If we should be going forward
            //brakes off.
            set eWheelThrottle to targetspeed - GROUNDSPEED.
            set iWheelThrottle to min( 1, max( -1, iWheelThrottle + 
                                                (looptime * eWheelThrottle))).
            set wtVAL to eWheelThrottle + iWheelThrottle.//PI controler
            if GROUNDSPEED < 5 {
                //Safety adjustment to help reduce roll-back at low speeds
                set wtVAL to min( 1, max( -0.2, wtVAL)).
                }
            }
        else if targetspeed < 0 { //Else if we're going backwards
            set wtVAL to SHIP:CONTROL:PILOTWHEELTHROTTLE.
            set targetspeed to 0. //Manual reverse throttle
            set iWheelThrottle to 0.
            }
        else { // If value is out of range or zero, stop.
            set wtVAL to 0.
            brakes on.
            }

        if brakes = 1 { //Disable cruise control if the brakes are turned on.
            set targetspeed to 0.
            }        
        
        //Steering:
        if AG1 { //Activate autopilot if Actiong group 1 is on
            set errorSteering to (targetheading - cHeading).
            if errorSteering > 180 { //Make sure the headings make sense
                set errorSteering to errorSteering - 360.
                }
            else if errorSteering < -180 {
                set errorSteering to errorSteering + 360.
                }
            set desiredSteering to -errorSteering / 10.
            set kturn to min( 1, max( -1, desiredSteering)) * turnlimit.
            }
        else {
            set kturn to turnlimit * SHIP:CONTROL:PILOTWHEELSTEER.
            }
        

        }
    
    //Handle User Input using action groups
        if AG2 { // Set heading to the current heading
            set targetHeading to cHeading.
            set AG2 to FALSE. //Reset the AG after we read it
            } 
        else if AG3 { // Decrease the heading
            set targetHeading to targetHeading - 0.5.
            set AG3 to FALSE.
            } 
        else if AG4 { // Increase the heading
            set targetHeading to targetHeading + 0.5.
            set AG4 to FALSE.
             }
        else if AG5 {
             set targetHeading to targetHeading - 0.5.
             set AG6 to FALSE. 
             //Prevent increase if we are decreasing
             }
        else if AG6 {
             set targetHeading to targetHeading + 0.5.
             set AG5 to FALSE. 
             //Prevent decrease if we are increasing
             }
                
        if targetHeading > 360 {
            set targetHeading to targetHeading - 360.
            }
        else if targetHeading < 0 {
            set targetHeading to targetHeading + 360.
            }


    set SHIP:CONTROL:WHEELTHROTTLE to WTVAL.
    set SHIP:CONTROL:WHEELSTEER to kTurn.
    
    
    print "Target Speed:   " + round( targetspeed, 1) + "        " at (2, 3).    
    print "Speed Limit:    " + round( speedlimit, 1) + "        " at (2, 4).
    print "Surface Speed:  " + round( GROUNDSPEED, 1) + "        " at (2, 5).
    
    print "Pilot Throttle: " + round( SHIP:CONTROL:PILOTWHEELTHROTTLE, 2) 
            + "        " at (2, 7).
    print "Kommanded tVAL: " + round( wtVAL, 2) + "        " at (2, 8).
    print "Pilot Turn:     " + round( SHIP:CONTROL:PILOTWHEELSTEER, 2) 
            + "        " at (2, 9).
    print "Kommanded Turn: " + round( kTurn, 2) + "        " at (2, 10).
    
    print "Target Heading: " + round( targetheading, 2) + "        " at (2, 12).
    print "CurrentHeading: " + round( cheading, 2) + "        " at (2, 13).
    print "Cruise Control: " + AG1 + "   " at (2, 14).
    
    print "E: " + round(eWheelThrottle,2)+ "   "  at ( 2, 16).
    print "I: " + round(iWheelThrottle,2) + "   " at (10,16).
    
    set looptime to TIME:SECONDS - loopEndTime.
    set loopEndTime to TIME:SECONDS.
    
    }