// Add all fuels you want to check in to this list (e.g. Karbonite if you use the mod),
// but SolidFuel is intentionaly left out and Oxidizer is unimportant
global stagingFuelList	is list("LiquidFuel").
global stagingNumber	is -1.
global stagingEngines	is list().
global stagingTanks		is list().

// to be called whenever current stage changes to prepare data for quicker test.
//
// prepares a list of engines that are in current stage but not in next stage.
// counts fuel in each and decides which to add to the "flameout watch list"
// that drives the staging behavior.
//
// HOW IT WORKS
// ------------
// for most parts, :STAGE is the stage number they separate in; for engines,
// this is the number they activate in.
// e:parent:stage is different works for any engine that is not attached
// directly to another engine. boosters are engines and therefore this fails
// for booster-on-booster arrangements; all will stage at once even if they're
// not all depleted.
function stagingPrepare {
	wait until stage:ready.
	set stagingNumber	to stage:number.
	set stagingEngines	to list().
	set stagingTanks	to list().
	if stage:number = 0 return.

	list engines in engines.
	for e in engines if e:stage = stage:number and e:parent:stage = stage:number-1
		stagingEngines:add(e).

	// prepare list of tanks that are in current stage but not in next stage
	list parts in parts.
	for t in parts if t:stage = stage:number-1 {
		local amount is 0.
		for r in t:resources if stagingFuelList:contains(r:name)
			set amount to amount + r:amount.
		if amount > 0.01
			stagingTanks:add(t).
	}
}

// to be called repeatedly
function stagingCheck {
	if stage:number <> stagingNumber
		stagingPrepare().
	wait until stage:ready.

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
			for r in t:resources if stagingFuelList:contains(r:name)
				set amount to amount + r:amount.
			if amount > 0.01 return false.
		}
		return true.
	}

	if checkEngines() or checkTanks() or availableThrust = 0 {
		stage.
		// this is optional and unnecessary if TWR does not change much,
		// but can prevent weird steering behaviour after staging
		steeringManager:resetPids().
		wait until stage:ready.
	}
}

stagingPrepare().
