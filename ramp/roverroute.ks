@lazyglobal off.

Parameter MaxSpeed is 28.
Parameter WaypointTolerance is 5.

runoncepath("lib_ui").

local AllFiles is list().
local Routes is list().

if HomeConnection:IsConnected {
	// Read the route files
	local LocalPath is ScriptPath().
	switch to 0.
	cd("/routes").
	list files in AllFiles.
	for F in AllFiles {
		if f:isfile and f:extension() = "json"{
			Routes:Add(f).
		}
	}.
	local SelectedIndex is uiTerminalList(Routes).
	local Route is list().
	local RawPoints is readjson(Routes[SelectedIndex]).
	for p in RawPoints {
		Route:Add(latlng(p["lat"],p["lng"])).
	}
	switch to LocalPath:Volume.
	cd(LocalPath:Parent).
	run rover_autosteer(Route,WaypointTolerance,MaxSpeed).
}
else uiError("Route","There is no connection to KSC servers. Raise antennas and try again.").
