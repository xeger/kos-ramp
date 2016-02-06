/////////////////////////////////////////////////////////////////////////////
// Depart from dock
/////////////////////////////////////////////////////////////////////////////
// Undocks the CPU vessel and casts off with a small amount of velocity.
//
// WARNING: if your vessel is docked to multiple things, this chooses
//   one random port to undock; the result is unpredictable and may
//   not be what you wanted!
//
// TODO: be smarter about choosing whom to undock from (always choose most
//       massive docking peer)
/////////////////////////////////////////////////////////////////////////////

clearvecdraws().
run once lib_ui.
run once lib_dock.

local myPort is dockChooseDeparturePort().
local station is ship.

if myPort = 0 {
  uiError("Depart", core:element:name + " does not appear to be docked").
  reboot.
}

sas off.
rcs off.
myPort:undock.
wait 0.5.
sas on.
wait 0.5.
rcs on.

lock vel to station:velocity:orbit - ship:velocity:orbit.

until vel:mag > 1 {
  set ship:control:fore to -1.
}
set ship:control:fore to 0.

rcs off.

uiBanner("Depart", "Undocked from " + station:name).
