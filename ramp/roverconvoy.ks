@lazyglobal off.

runoncepath("lib_ui").

local AllTargets is List().
local ValidTargets is List().
local Names is List().
list targets in AllTargets.

for tgt in AllTargets {
	if tgt:body = ship:body and tgt:type = "Rover" {
		ValidTargets:add(tgt).
		Names:add(tgt:name).
	}
}

local SelectedIndex is uiTerminalList(Names).
run rover_autosteer(ValidTargets[SelectedIndex], 30).
