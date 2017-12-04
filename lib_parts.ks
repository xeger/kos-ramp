FUNCTION partsExtendAntennas { 
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("Extend") { M:DOACTION(A,True). }
            }.
        }
    }.
}

FUNCTION partsRetractAntennas {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("Retract") { M:DOACTION(A,True). }
            }.
        }
    }.
}

FUNCTION partsDisableReactionWheels {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleReactionWheel") {
            LOCAL M IS P:GETMODULE("ModuleReactionWheel").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("deactivate") { M:DOACTION(A,True). }
            }.
        }
    }.
}

FUNCTION partsEnableReactionWheels {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleReactionWheel") {
            LOCAL M IS P:GETMODULE("ModuleReactionWheel").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("activate") { M:DOACTION(A,True). }
            }.
        }
    }.
}

FUNCTION partsRetractRadiators {
    //If you want to turn on or off all the radiators you can use the built in variable RADIATORS, ie:
    // RADIATORS ON. 
    // RADIATORS OFF.
    // This function only retract deployable radiators. Useful for reentry. 
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableRadiator") {
            LOCAL M IS P:GETMODULE("ModuleDeployableRadiator").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("Retract") { M:DOACTION(A,True). }
            }.
        }
    }.
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
    local ReturnValue is false.
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleProceduralFairing") {
            LOCAL M IS P:GETMODULE("ModuleProceduralFairing").
            FOR Event IN M:ALLEVENTNAMES() {
                IF Event:CONTAINS("deploy") {
                    M:DOEVENT(Event).
                    set ReturnValue to True.
                } 
            }.
        }
    }.
    Return ReturnValue.
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
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleParachute") {
            LOCAL M IS P:GETMODULE("ModuleParachute").
            FOR Event IN M:ALLEVENTNAMES() {
                IF Event:CONTAINS("disarm") M:DOEVENT(Event). 
            }.
        }
    }.
}