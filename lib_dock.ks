/////////////////////////////////////////////////////////////////////////////
// Docking functions
/////////////////////////////////////////////////////////////////////////////
// Shared logic for docking
/////////////////////////////////////////////////////////////////////////////

run lib_pid.

// Constant docking parameters
local dock_scale is 100. // X/Y/Z velocity scaling factor (m)
local dock_start is 25.  // ideal start distance (m)
local dock_final is 3.   // final approach distance (m)
local dock_limit is 5.   // max X/Y/Z speed (m/s)
local dock_creep is 1.   // creep-forward speed (m/s)
local dock_touch is 0.2. // final approach speed (m/s)

// Velocity controllers (during alignment)
global dock_X1 is pidInit(1.4, 0.1, 2.0, -1, 1).
global dock_Y1 is pidInit(1.4, 0.1, 2.0, -1, 1).

// Position controllers (during approach)
global dock_X2 is pidInit(0.4, 0, 1.4, -1, 1).
global dock_Y2 is pidInit(0.4, 0, 1.4, -1, 1).

// Shared velocity controller
global dock_Z is pidInit(0.8, 0.4, 0.2, -1, 1).

// UI flourishes
global dock_announce is 0.
global dock_announceMsg is "".

function dockBack {
  parameter pos, vel.

  set ship:control:fore to -pidSeek(dock_Z, dock_limit, vel:Z).
}

function dockAlign {
  parameter pos, vel.

  // Taper X/Y speed according to distance from goal
  local vScaleX is min(abs(pos:X / dock_scale), 1).
  local vScaleY is min(abs(pos:Y / dock_scale), 1).
  local vWantX is -(pos:X / abs(pos:X)) * dock_limit * vScaleX.
  local vWantY is -(pos:Y / abs(pos:Y)) * dock_limit * vScaleY.

  if pos:Z > dock_start {
    // Move forward at some speed between creep and limit
    // Tolerate a range of speeds; save juice for the approach
    if vel:Z > -dock_limit and vel:Z < -dock_creep {
      pidSeek(dock_Z, -dock_creep, vel:Z).
      set ship:control:fore to 0.
    } else {
      set ship:control:fore to -pidSeek(dock_Z, -dock_creep, vel:Z).
    }
  } else {
    // Too close: halt forward speed & keep aligning
    set ship:control:fore to -pidSeek(dock_Z, 0, vel:Z).
  }

  // Hold transverse velocity at setpoint
  set ship:control:starboard to pidSeek(dock_X1, vWantX, vel:X).
  set ship:control:top to pidSeek(dock_Y1, vWantY, vel:Y).
}

function dockApproach {
  parameter pos, vel.

  local vScaleZ is min(abs(pos:Z / dock_scale), 1).

  if pos:Z < dock_final {
    // Final approach: barely inch forward!
    set ship:control:fore to -pidSeek(dock_Z, -dock_touch, vel:Z).
  } else {
    // Move forward at a distance-dependent speed between
    // creep and limit
    set ship:control:fore to -pidSeek(dock_Z, -max(dock_creep, dock_limit*vScaleZ), vel:Z).
  }

  // Stay aligned
  set ship:control:starboard to pidSeek(dock_X2, 0, pos:X).
  set ship:control:top to pidSeek(dock_Y2, 0, pos:Y).
}

function dockAnnounce {
  parameter msg.

  if (time:seconds - dock_announce > 60) or (dock_announceMsg <> msg) {
    uiBanner("Dock", msg).
    set dock_announce to time:seconds.
    set dock_announceMsg to msg.
  }
}

function dockChoosePorts {
  local hisPort is 0.
  local myPort is 0.

  local myMods is ship:modulesnamed("ModuleDockingNode").
  for mod in myMods {
    //if mod:part:controlfrom = true {
      set myPort to mod:part.
    //}
  }

  if myPort <> 0 {
    local myMass is myPort:mass.

    // HACK: distinguish between targeted vessel and targeted port using mass > 2 tonnes
    if target:mass > 2.0 {
      local hisMods is target:modulesnamed("ModuleDockingNode").
      local tgtPos is target:position.
      local bestAngle is 180.
      for mod in hisMods {
        if abs(mod:part:mass - myMass) < 0.1 and vang(tgtPos, mod:part:position) < bestAngle and vdot(myPort:portfacing:forevector, mod:part:portfacing:forevector) < 0 {
          set hisPort to mod:part.
        }
      }
    } else {
      set hisPort to target.
    }

    if hisPort <> 0 {
      set target to hisPort.
    } else {
      return 0.
    }
  }

  return myPort.
}

function dockComplete {
  parameter port.

  if port:state = "Docked (docker)" or port:state = "Docked (dockee)" or port:state = "Docked (same vessel)" {
    return true.
  } else {
    return false.
  }
}
