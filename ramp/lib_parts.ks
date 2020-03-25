// events are preferred because there are no restrictions
function partsDoEvent {
	parameter module.
	parameter event.
	parameter tag is "".

	set event to "^" + event + "\b". // match first word
	local success is false.
	local maxStage is -1.
	if tag = "" and (defined stagingMaxStage)
		set maxStage to stagingMaxStage - 1. // see lib_staging
	for p in ship:partsTagged(tag) {
		if p:stage >= maxStage and p:modules:contains(module) {
			local m is p:getModule(module).
			for e in m:allEventNames() {
				if e:matchesPattern(event) {
					m:doEvent(e).
					set success to true.
				}
			}
		}
	}
	return success.
}

// actions are only accessible if VAB or SPH upgraded enough
function partsDoAction {
	parameter module.
	parameter action.
	parameter tag is "".

	local success is false.
	if Career():canDoActions {
		set action to "^" + action + "\b". // match first word
		local maxStage is -1.
		if tag = "" and (defined stagingMaxStage)
			set maxStage to stagingMaxStage - 1. // see lib_staging
		for p in ship:partsTagged(tag) {
			if p:stage >= maxStage and p:modules:contains(module) {
				local m is p:getModule(module).
				for a in m:allActionNames() {
					if a:matchesPattern(action) {
						m:doAction(a, true).
						set success to true.
					}
				}
			}
		}
	}
	return success.
}

function partsExtendSolarPanels {
	parameter tag is "".
	return partsDoEvent("ModuleDeployableSolarPanel", "extend", tag).
}

function partsRetractSolarPanels {
	parameter tag is "".
	return partsDoEvent("ModuleDeployableSolarPanel", "retract", tag).
}

function partsExtendAntennas {
	parameter tag is "".
	return partsDoEvent("ModuleDeployableAntenna", "extend", tag).
}

function partsRetractAntennas {
	parameter tag is "".
	return partsDoEvent("ModuleDeployableAntenna", "Retract", tag).
}

function partsDisableReactionWheels {
	parameter tag is "".
	return partsDoAction("ModuleReactionWheel", "deactivate", tag).
}

function partsEnableReactionWheels {
	parameter tag is "".
	return partsDoAction("ModuleReactionWheel", "activate", tag).
}

function partsRetractRadiators {
	// If you want to turn on or off all the radiators you can use the built in variable RADIATORS, ie:
	// RADIATORS on.
	// RADIATORS off.
	// This function only retract deployable radiators. Useful for reentry.
	parameter tag is "".
	return partsDoEvent("ModuleDeployableRadiator", "Retract", tag).
}

// Try to control from the specified docking port.
function partsControlFromDockingPort {
	parameter cPart. // The docking port you want to control from.
	local success is false.

	// Try to control from the port
	if cPart:modules:contains("ModuleDockingNode") {
		local m is cPart:getModule("ModuleDockingNode").
		for event in m:allEventNames() {
			if event:contains("Control") { m:doevent(event). success on. }
		}.
	}

	// Try to open/deploy the port
	if cPart:modules:contains("ModuleAnimateGeneric") {
		local m is cPart:getModule("ModuleAnimateGeneric").
		for event in m:allEventNames() {
			if event:contains("open") or event:contains("deploy") or event:contains("extend") { m:doevent(event). }
		}.
	}

	return success.
}

function partsDeployFairings {
	return partsDoEvent("ModuleProceduralFairing", "deploy").
}

function partsHasTermometer {
	// Checks if ship have required sensors:
	// - Termometer
	local HasT is false.
	list sensors in sensorsList.
	for s in sensorsList {
		if s:type = "TEMP" { set HasT to true. }
	}
	return HasT.
}

function partsDisarmsChutes {
	// Make sure all chutes are disarmed, even if already staged.
	// Warning: If chutes are staged and disarmed, SPACEBAR will not deploy they!
	//   Use 'chutes on.' command or right click menu.
	return partsDoAction("ModuleParachute", "disarm").
}

function partsPercentEC {
	for R in ship:resources {
		if R:name = "ELECTRICCHARGE" {
			return R:amount / R:capacity * 100.
		}
	}
	return 0.
}

function partsPercentLFO {
	local LFCAP is 0.
	local LFAMT is 0.
	local OXCAP is 0.
	local OXAMT is 0.
	for R in ship:resources {
		if R:name = "LIQUIDFUEL" {
			set LFCAP to R:capacity.
			set LFAMT to R:amount.
		} else if R:name = "OXIDIZER" {
			set OXCAP to R:capacity.
			set OXAMT to R:amount.
		}
	}
	if OXCAP = 0 or LFCAP = 0 {
		return 0.
	} else {
		if OXCAP * (11 / 9) < LFCAP { // Surplus fuel
			return OXAMT / OXCAP * 100.
		} else { // Surplus oxidizer or proportional amonts
			return LFAMT / LFCAP * 100.
		}
	}
}

function partsPercentMP {
	for R in ship:resources {
		if R:name = "MONOPROPELLANT" {
			return R:amount / R:capacity * 100.
		}
	}
	return 0.
}

function partsMMEngineClosedCycle {
	for p in ship:parts {
		if p:modules:contains("MultiModeEngine") {
			local m is p:getModule("MultiModeEngine").
			if m:HasField("mode") and m:GetField("mode"):Contains("Air") {
				for event in m:allEventNames() {
					if event:contains("toggle") m:DoEvent(event).
				}.
			}
		}
	}.
}

function partsMMEngineAirBreathing {
	for p in ship:parts {
		if p:modules:contains("MultiModeEngine") {
			local m is p:getModule("MultiModeEngine").
			if m:HasField("mode") and m:GetField("mode"):Contains("Closed") {
				for event in m:allEventNames() {
					if event:contains("toggle") m:DoEvent(event).
				}.
			}
		}
	}.
}


function partsReverseThrust {
	return partsDoAction("ModuleAnimateGeneric", "reverse").
}

function partsForwardThrust {
	return partsDoAction("ModuleAnimateGeneric", "forward").
}
