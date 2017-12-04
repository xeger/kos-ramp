@lazyglobal off.

FUNCTION TerrainNormalVector {
    // Thanks to Ozin
    // Returns a vector normal to the terrain
    parameter radius is 2. //Radius of the terrain sample
    local p1 to body:geopositionof(facing:vector * radius).
    local p2 to body:geopositionof(facing:vector * -radius + facing:starvector * radius).
    local p3 to body:geopositionof(facing:vector * -radius + facing:starvector * -radius).

    local p3p1 to p3:position - p1:position.
    local p2p1 to p2:position - p1:position.

    local normalvec to vcrs(p2p1,p3p1).
    return normalvec.
}