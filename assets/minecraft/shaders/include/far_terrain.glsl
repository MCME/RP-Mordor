// How far the world is drawn, for the shaders that need to know: the eye
// (fire_eye.glsl), the clouds carrying it from afar (core/rendertype_clouds.vsh)
// and particles (core/particle.vsh).

// The server's view distance, 15 chunks, in blocks: chunks past it are never
// sent, so nothing in them is drawn.
#define SERVER_VIEW_DISTANCE 240.0

// Whether a distant terrain mod draws the world past the render distance,
// from the render distance fog's start, which they move far off: Distant
// Horizons to 4.2e14 blocks, with vanilla fog switched off in its settings
// (its default), and Voxy to 1e9. Nothing else moves it past 1e8.
bool farTerrain(float renderFogStart) {
    return renderFogStart > 1.0e8;
}

// How thick Distant Horizons' fog is at the fire eye, 0 to 1, from the render
// distance fog: with its start far past anything drawn, its end makes no fog,
// and MCME's mod sets it to the start * (2 + that). 0 without the mod (the
// end is then vanilla's, far under the start), or without DH's fog. DH fogs
// only its LODs, not the sky the eye is painted on from afar (fire_eye_sky.glsl).
float farTerrainFog(float renderFogStart, float renderFogEnd) {
    if (!farTerrain(renderFogStart)) return 0.0;
    return clamp(renderFogEnd / renderFogStart - 2.0, 0.0, 1.0);
}
