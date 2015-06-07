// Immediate launch.

run ui.

stage.

local atmo is body:atm:height.
local gt0  is atmo * 0.1.
local gt1  is atmo * 0.90.
local apo  is atmo + (body:radius / 3).

if atmo > 0 {
  uiStatus("Launch", "Ascend to " + round(apo / 1000) + "km; turn " + round(gt0 / 1000) + " - " + round(gt1 / 1000) + "km").
} else {
  //in vacuum, gravity turn @ 100m AGL to clear obstacles
  uiStatus("Launch", "Ascend to " + round(apo / 1000) + "km").
  set gt0 to 100.
  set gt1 to 250.
}

run launch_asc(gt0, gt1, apo).
