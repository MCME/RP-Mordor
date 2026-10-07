// RP-Mordor's own terrain features, hooked into the shader base's terrain
// fragment shaders - vanilla's and Sodium's (see mcme_hook_vertex_globals).
// The base's fluid.glsl, which the tar builds on, is imported, and so is its
// lava module, which Mordor turns on in its .mcme-shaders.json.

// the fire eye (fire_eye.glsl)
flat in int fireLayer;
flat in vec3 fireCentre;
flat in vec3 fireOrigin;
#define FIRE_ORIGIN fireOrigin
// the game's time, set in main: Sodium's own clock restarts with each region,
// and the sky, which draws the eye from afar, has only the game's
float fireTime = 0.0;
#moj_import <minecraft:far_terrain.glsl>
#moj_import <minecraft:fire_eye_config.glsl>
#moj_import <minecraft:fire_eye.glsl>

// the tar
#moj_import <minecraft:mordor_fluid.glsl>
#moj_import <minecraft:tar_config.glsl>
#moj_import <minecraft:tar.glsl>
