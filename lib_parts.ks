FUNCTION partsDoIt {
    PARAMETER MODULENAME.
    PARAMETER ACTIONNAME.
    PARAMETER TAG IS "".
    
    LOCAL SUCCESS IS FALSE.
    IF Career():CANDOACTIONS {
        FOR P IN SHIP:PARTSTAGGED(TAG) {
            IF P:MODULES:CONTAINS(MODULENAME) {
                LOCAL M IS P:GETMODULE(MODULENAME).
                FOR A IN M:ALLACTIONNAMES() {
                    IF A:CONTAINS(ACTIONNAME) {
                        M:DOACTION(A,True).
                        SET SUCCESS TO TRUE.
                    }
                }.
            }
        }.
    }
    RETURN SUCCESS.
}

FUNCTION partsExtendSolarPanels {
    PARAMETER TAG IS "".
    partsDoIt("ModuleDeployableSolarPanel", "Extend", TAG).
}

FUNCTION partsRetractSolarPanels {
    PARAMETER TAG IS "".
    partsDoIt("ModuleDeployableSolarPanel", "Retract", TAG).
}

FUNCTION partsExtendAntennas {
    PARAMETER TAG IS "".
    partsDoIt("ModuleDeployableAntenna", "Extend", TAG).
}

FUNCTION partsExtendAntennas {
    PARAMETER TAG IS "".
    partsDoIt("ModuleDeployableAntenna", "Retract", TAG).
}

FUNCTION partsDisableReactionWheels {
    PARAMETER TAG IS "".
    partsDoIt("ModuleReactionWheel", "deactivate", TAG).
}

FUNCTION partsEnableReactionWheels {
    PARAMETER TAG IS "".
    partsDoIt("ModuleReactionWheel", "activate", TAG).
}

FUNCTION partsRetractRadiators {
    //If you want to turn on or off all the radiators you can use the built in variable RADIATORS, ie:
    // RADIATORS ON.
    // RADIATORS OFF.
    // This function only retract deployable radiators. Useful for reentry.
    PARAMETER TAG IS "".
    partsDoIt("ModuleDeployableRadiator", "Retract", TAG).
}


//Try to control from the specified docking port.
FUNCTION partsControlFromDockingPort {
    parameter cPart. //The docking port you want to control from.
    local success is false.

    // Try to control from the port
    if cPart:MODULES:CONTAINS("ModuleDockingNode") {
        LOCAL M IS cPart:GETMODULE("ModuleDockingNode").
        FOR Event IN M:ALLEVENTNAMES() {
            IF Event:CONTAINS("Control") { M:DOEVENT(Event). success on. }
        }.
    }

    // Try to open/deploy the port
    if cPart:MODULES:CONTAINS("ModuleAnimateGeneric") {
        LOCAL M IS cPart:GETMODULE("ModuleAnimateGeneric").
        FOR Event IN M:ALLEVENTNAMES() {
            IF Event:CONTAINS("open") or Event:CONTAINS("deploy") or Event:CONTAINS("extend") { M:DOEVENT(Event). }
        }.
    }

    Return success.
}

FUNCTION partsDeployFairings {
    RETURN partsDoIt("ModuleProceduralFairing", "deploy").
}

FUNCTION partsHasTermometer {
// Checks if ship have required sensors:
// - Termometer
LOCAL HasT IS False.
LIST SENSORS IN SENSELIST.
FOR S IN SENSELIST {
    IF S:TYPE = "TEMP" { SET HasT to True. }
}
RETURN HasT.
}


FUNCTION partsDisarmsChutes {
    // Make sure all chutes are disarmed, even if already staged.
    // Warning: If chutes are staged and disarmed, SPACEBAR will not deploy they!
    //          Use CHUTES ON. command or right click menu.
    partsDoIt("ModuleParachute", "disarm").
}

FUNCTION partsPercentEC {
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "ELECTRICCHARGE" {
            RETURN R:AMOUNT / R:CAPACITY * 100.
        }
    }
    RETURN 0.
}

FUNCTION partsPercentLFO {
    LOCAL LFCAP IS 0.
    LOCAL LFAMT IS 0.
    LOCAL OXCAP IS 0.
    LOCAL OXAMT IS 0.
    LOCAL SURPLUS IS 0.
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "LIQUIDFUEL" {
            SET LFCAP TO R:CAPACITY.
            SET LFAMT TO R:AMOUNT.
        }
        ELSE IF R:NAME = "OXIDIZER" {
            SET OXCAP TO R:CAPACITY.
            SET OXAMT TO R:AMOUNT.
        }
    }
    IF OXCAP = 0 OR LFCAP = 0 {
        RETURN 0.
    }
    ELSE {
        IF OXCAP * (11/9) < LFCAP { // Surplus fuel
            RETURN OXAMT/OXCAP*100.
        }
        ELSE { // Surplus oxidizer or proportional amonts
            RETURN LFAMT/LFCAP*100.
        }
    }
}

FUNCTION partsPercentMP {
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "MONOPROPELLANT" {
            RETURN R:AMOUNT / R:CAPACITY * 100.
        }
    }
    RETURN 0.
}

FUNCTION partsMMEngineClosedCycle {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("MultiModeEngine") {
            LOCAL M IS P:GETMODULE("MultiModeEngine").
			IF M:HasField("mode") and M:GetField("mode"):Contains("Air") {
				FOR Event IN M:ALLEVENTNAMES() {
					IF Event:CONTAINS("toggle") M:DoEvent(Event).
				}.
			}
		}
    }.
}

FUNCTION partsMMEngineAirBreathing {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("MultiModeEngine") {
            LOCAL M IS P:GETMODULE("MultiModeEngine").
			IF M:HasField("mode") and M:GetField("mode"):Contains("Closed") {
				FOR Event IN M:ALLEVENTNAMES() {
					IF Event:CONTAINS("toggle") M:DoEvent(Event).
				}.
			}
		}
    }.
}


FUNCTION partsReverseThrust {
    RETURN partsDoIt("ModuleAnimateGeneric", "reverse").
}

FUNCTION partsForwardThrust {
    partsDoIt("ModuleAnimateGeneric", "forward").
}
