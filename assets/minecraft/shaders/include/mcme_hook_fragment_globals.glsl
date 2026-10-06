// RP-Mordor's own terrain features, hooked into the shader base's terrain
// fragment shaders - vanilla's and Sodium's (see mcme_hook_vertex_globals).
// The base's fluid.glsl, which the lava, the ice and the tar build on, is
// imported.

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

// the lava, the ice and the tar
#moj_import <minecraft:lava_config.glsl>
#moj_import <minecraft:lava.glsl>
#moj_import <minecraft:ice_config.glsl>
#moj_import <minecraft:ice.glsl>
#moj_import <minecraft:mordor_fluid.glsl>
#moj_import <minecraft:tar_config.glsl>
#moj_import <minecraft:tar.glsl>
