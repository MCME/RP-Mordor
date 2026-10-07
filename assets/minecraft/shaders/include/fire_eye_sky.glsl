// The fire eye on the sky (core/sky.vsh, sky.fsh): with a distant terrain
// mod, past FIRE_HANDOVER, where its block isn't drawn. Needs globals.glsl,
// fog.glsl, far_terrain.glsl and fire_eye_config.glsl.

// how far in the sky disc's rim is pulled, as it is pulled down to -500
#define FIRE_SKY_PULL 0.2

// whether the eye is painted on the sky - and so the disc pulled into a
// pyramid - this frame
bool fireSkyPulled() {
    return farTerrain(FogRenderDistanceStart)
        && length(vec3(FIRE_EYE_BLOCK - CameraBlockPos)) > FIRE_HANDOVER - 16.0;
}

// Distant Horizons' fog at the eye, 0 to 1 (far_terrain.glsl), which it
// takes on near the horizon only (fire_eye.glsl's fireFogShare)
float fireSkyFog() {
    return farTerrainFog(FogRenderDistanceStart, FogRenderDistanceEnd);
}

// Where vanilla's sky disc above - a fan from (0, 16, 0) to 8 points at 512
// round it, 45 degrees apart - lies in direction dir, and the fog distances
// its vertices give there: false past its rim, where the frame's clear colour
// shows instead.
bool fireSkyDisc(vec3 dir, out float spherical, out float cylindrical) {
    spherical = cylindrical = 0.0;
    if (dir.y <= 0.0) return false;
    vec2 at = dir.xz * (16.0 / dir.y);
    // how far out towards the rim's nearest edge, 0 to 1
    float sector = radians(45.0);
    float angle = atan(at.y, at.x);
    float reach = length(at) * cos(angle - (floor(angle / sector) + 0.5) * sector) / (512.0 * cos(radians(22.5)));
    if (reach > 1.0) return false;
    spherical = mix(16.0, length(vec2(512.0, 16.0)), reach);
    cylindrical = mix(16.0, 512.0, reach);
    return true;
}
