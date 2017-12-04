@lazyglobal off.
/////////////////////////////////////////////////////////////////////////////
// Undock
/////////////////////////////////////////////////////////////////////////////
// Undocks the ship.
//
// Finds a docked port, undock it and use RCS to back away, then return the
// control to the root/control part.
/////////////////////////////////////////////////////////////////////////////

runoncepath("lib_dock").
runoncepath("lib_util").
runoncepath("lib_ui").

local DepartDistance is 90.
local DepartSpeed is 3.
local StepWait is 3.

local DPort is dockChooseDeparturePort().
local TargetUndock is core:vessel.

if DPort <> 0 {
    wait StepWait. uiBanner("Undock","Releasing the dock port",2).
    // Undocks and wait a little to physics stabilize.
    DPort:Undock(). wait StepWait.
    
    //Switch control to our vessel and target the one we just undocked.
    uiBanner("Undock","Controlling from "+ ship:name).
    set KUniverse:ActiveVessel to core:vessel. wait StepWait.
    set Target to TargetUndock. wait StepWait.
    uiBanner("Undock","Departing from "+Target:name).

    // Back up from the target
    rcs on.
    lock steering to ship:facing.
    local lock TargetSpeed to -(target:velocity:orbit - ship:velocity:orbit). 
    until TargetSpeed:mag >= DepartSpeed or Target:Distance >= DepartDistance {
        local Thrust is min(1,max(0.1,DepartSpeed-TargetSpeed:mag)).
        set ship:control:translation to v(0,0,-Thrust).
        wait 0.
    }
    set ship:control:translation to v(0,0,0).
    wait until Target:Distance >= DepartDistance.

    // Restore control to the default part 
    // The default part is the root part or the first controllable one it can fine.
    // To override it, Tag a part as "Control" in VAB/SPH.
    dockControlFromCore(dockDefaultControlPart()).
    lock steering to lookdirup(-target:position,ship:up:vector).
    wait until utilIsShipFacing(-target:position,10,0.1).
    utilRCSCancelVelocity(TargetSpeed@,0.1).
    unlock steering.
    ship:control:neutralize on.
    sas on.
    rcs off.
    uiBanner("Undock","Undocking complete.",2).
}
else uiError("Undock","No docking port is docked now").