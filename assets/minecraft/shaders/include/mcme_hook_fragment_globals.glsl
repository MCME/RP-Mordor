// RP-Mordor's own terrain features, hooked into the shader base's terrain
// fragment shaders - vanilla's and Sodium's (see mcme_hook_vertex_globals).
// The base's fluid.glsl, which the lava and the ice build on, is imported.

// the fire eye (fire_eye.glsl)
flat in int fireLayer;
flat in vec3 fireCentre;
flat in float fireTime;
#moj_import <minecraft:far_terrain.glsl>
#moj_import <minecraft:fire_eye_config.glsl>
#moj_import <minecraft:fire_eye.glsl>

// the lava and the ice
#moj_import <minecraft:lava_config.glsl>
#moj_import <minecraft:lava.glsl>
#moj_import <minecraft:ice_config.glsl>
#moj_import <minecraft:ice.glsl>
