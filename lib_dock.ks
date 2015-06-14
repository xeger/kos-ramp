global dock_announce is 0.

function dockAnnounce {
  parameter msg.

  if time:seconds - dock_announce > 10 {
    uiBanner("Dock", msg).
    set dock_announce to time:seconds.
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

    local hisMods is target:modulesnamed("ModuleDockingNode").
    local tgtPos is target:position.
    local bestAngle is 180.
    for mod in hisMods {
      if abs(mod:part:mass - myMass) < 0.1 and vang(tgtPos, mod:part:position) < bestAngle and vdot(myPort:portfacing:forevector, mod:part:portfacing:forevector) < 0 {
        set hisPort to mod:part.
      }
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
