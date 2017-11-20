FUNCTION ExtendAntennas {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("Extend") { M:DOACTION(A,True). }
            }.
        }
    }.
}

FUNCTION RetractAntennas {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            FOR A IN M:ALLACTIONNAMES() {
                IF A:CONTAINS("Retract") { M:DOACTION(A,True). }
            }.
        }
    }.
}