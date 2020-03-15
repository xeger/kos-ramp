// Library for staging logic and deltaV calculation
// ================================================
// Asparagus and designs that throw off empty tanks were considered.
// Note that engines attached to tanks that get empty will be staged
// (even if not technically flamed out - that is something that KER and MechJeb do not consider).

// LOGIC: Stage if either availableThrust = 0 (separator-only, fairing-only stage)
// or all engines that are to be separated by staging flame out
// or all tanks (and boosters) to be separated that were not empty are empty now

// TAG NOAUTO: use "noauto" tag on any decoupler to instruct this library to never stage it
// note: can use multiple tags if separated by whitespace (e.g. "noauto otherTag") or other word-separators ("tag, noauto.anything;more").

// list of all consumed fuels (for deltaV; add e.g. Karbonite and/or MonoPropellant if using such mods)
if not (defined stagingConsumed)
	global stagingConsumed is list("SolidFuel", "LiquidFuel", "Oxidizer").

// list of fuels for empty-tank identification (for dual-fuel tanks use only one of the fuels)
// note: SolidFuel is in list for booster+tank combo, both need to be empty to stage
if not (defined stagingTankFuels)
	global stagingTankFuels is list("SolidFuel", "LiquidFuel"). // Oxidizer intentionally not included (would need extra logic)

// list of modules that identify decoupler
if not (defined stagingDecouplerModules)
	global stagingDecouplerModules is list("ModuleDecouple", "ModuleAnchoredDecoupler").

// Standard gravity for ISP
// https://en.wikipedia.org/wiki/Specific_impulse
// https://en.wikipedia.org/wiki/Standard_gravity
if not (defined isp_g0)
	global isp_g0 is kerbin:mu / kerbin:radius ^ 2. // exactly 9.81 in KSP 1.3.1, 9.80665 for Earth
// note that constant:G * kerbin:mass / kerbin:radius ^ 2 yields 9.80964723..., correct value could be 9.82

// work variables for staging logic
global stagingNumber is -1.      // stage:number when last calling stagingPrepare()
global stagingMaxStage is 0.     // stop staging if stage:number is lower or same as this
global stagingResetMax is true.  // reset stagingMaxStage to 0 if we passed it (search for next "noauto")
global stagingEngines is list(). // list of engines that all need to flameout to stage
global stagingTanks is list().   // list of tanks that all need to be empty to stage
// info for and from stageDeltaV
global stageAvgIsp is 0.         // average ISP in seconds
global stageStdIsp is 0.         // average ISP in N*s/kg (stageAvgIsp*isp_g0)
global stageDryMass is 0.        // dry mass just before staging
global stageBurnTime is 0.       // updated in stageDeltaV()

// return stage number where the part is decoupled (probably Part.separationIndex in KSP API)
function stagingDecoupledIn {
	parameter part.

	local function partIsDecoupler {
		parameter part.
		for m in stagingDecouplerModules if part:modules:contains(m) {
			if part:tag:matchesPattern("\bnoauto\b") and part:stage + 1 >= stagingMaxStage
				set stagingMaxStage to part:stage + 1.
			return true.
		}
		return false.
	}
	until partIsDecoupler(part) {
		if not part:hasParent return -1.
		set part to part:parent.
	}
	return part:stage.
}

// to be called whenever current stage changes to prepare data for quicker test and other functions
function stagingPrepare {

	wait until stage:ready.
	set stagingNumber to stage:number.
	if stagingResetMax and stagingMaxStage >= stagingNumber
		set stagingMaxStage to 0.
	stagingEngines:clear().
	stagingTanks:clear().

	// prepare list of tanks that are to be decoupled and have some fuel
	list parts in parts.
	for p in parts {
		local amount is 0.
		for r in p:resources if stagingTankFuels:contains(r:name)
			set amount to amount + r:amount.
		if amount > 0.01 and stagingDecoupledIn(p) = stage:number - 1
			stagingTanks:add(p).
	}

	// prepare list of engines that are to be decoupled by staging
	// and average ISP for stageDeltaV()
	list engines in engines.
	local thrust is 0.
	local flow is 0.
	for e in engines if e:ignition and e:isp > 0 {
		if stagingDecoupledIn(e) = stage:number - 1
			stagingEngines:add(e).

		local t is e:availableThrust.
		set thrust to thrust + t.
		set flow to flow + t / e:isp. // thrust=isp * g0 * dm / dt => flow = sum of thrust/isp
	}
	set stageAvgIsp to 0.
	if flow > 0 set stageAvgIsp to thrust / flow.
	set stageStdIsp to stageAvgIsp * isp_g0.

	// prepare dry mass for stageDeltaV()
	local fuelMass is 0.
	for r in stage:resources if stagingConsumed:contains(r:name)
		set fuelMass to fuelMass + r:amount * r:density.
	set stageDryMass to ship:mass - fuelMass.
}

// to be called repeatedly
function stagingCheck {
	wait until stage:ready.
	if stage:number <> stagingNumber
		stagingPrepare().
	if stage:number <= stagingMaxStage
		return.

	// need to stage because all engines are without fuel?
	local function checkEngines {
		if stagingEngines:empty return false.
		for e in stagingEngines if not e:flameout
			return false.
		return true.
	}

	// need to stage because all tanks are empty?
	local function checkTanks {
		if stagingTanks:empty return false.
		for t in stagingTanks {
			local amount is 0.
			for r in t:resources if stagingTankFuels:contains(r:name)
				set amount to amount + r:amount.
			if amount > 0.01 return false.
		}
		return true.
	}

	// check staging conditions and return true if staged, false otherwise
	if availableThrust = 0 or checkEngines() or checkTanks() {
		stage.
		// this is optional and unnecessary if TWR does not change much,
		// but can prevent weird steering behaviour after staging
		steeringManager:resetPids().
		// prepare new data
		stagingPrepare().
		return true.
	}
	return false.
}

// delta-V remaining for current stage
// + stageBurnTime updated with burn time at full throttle
function stageDeltaV {
	if stageAvgIsp = 0 or availableThrust = 0 {
		set stageBurnTime to 0.
		return 0.
	}

	set stageBurnTime to stageStdIsp * (ship:mass - stageDryMass) / availableThrust.
	return stageStdIsp * ln(ship:mass / stageDryMass).
}

// calculate burn time for maneuver needing provided deltaV
function burnTimeForDv {
	parameter dv.
	return stageStdIsp * ship:mass * (1 - constant:e ^ (-dv / stageStdIsp)) / availableThrust.
}

// current thrust to weght ratio
function thrustToWeight {
	return availableThrust / (ship:mass * body:mu) * (body:radius + altitude) ^ 2.
}
