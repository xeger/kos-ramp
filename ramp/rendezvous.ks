/////////////////////////////////////////////////////////////////////////////
// Rendezvous with target
/////////////////////////////////////////////////////////////////////////////
// Maneuver close to another vessel orbiting the same body.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

if ship:body <> target:body {
	uiError("Rendezvous", "Target outside of SoI").
	wait 5.
	reboot.
}

local accel is uiAssertAccel("Rendezvous").
local approachT is utilClosestApproach(ship, target).
local approachX is (positionat(target, approachT) - positionat(ship, approachT)):mag.

// Perform Hohmann transfer if necessary
if target:position:mag > 25000 and approachX > 25000 {
	local ri is abs(obt:inclination - target:obt:inclination).

	// Align if necessary
	if ri > 0.1 {
		uiBanner("Rendezvous", "Alignment burn").
		run node_inc_tgt.
		run node.
	}

	uiDebug("Running Hohmann transfer node calculation").
	run node_hoh.

	local strandedcount is 0.
	until HASNODE {
		set strandedcount to strandedcount + 1.
		uiBanner("Rendezvous", "Transfer to phasing orbit").
		run circ_alt(target:altitude * 1.666 * strandedcount).
		run node_hoh.
	}

	uiBanner("Rendezvous", "Transfer injection burn").
	run node.

	uiBanner("Rendezvous", "Matching velocity at closest approach.").
	run node_vel_tgt.
	run node.

}

run approach.

uiBanner("Rendezvous", "Approach to 150m").
wait until target:position:mag < 150.

run match.

//Save before dock!
wait until KUniverse:CanQuickSave().
KUniverse:QuickSaveTo("RAMP-Before docking").

run dock.
