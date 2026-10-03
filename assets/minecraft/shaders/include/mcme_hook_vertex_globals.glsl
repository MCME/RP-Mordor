// RP-Mordor's own terrain features, hooked into the shader base's terrain
// vertex shaders - vanilla's and Sodium's (ResourcePackScripts/shaderBase,
// docs/shader-base.md).

// the fire eye (fire_eye_main.glsl)
flat out int fireLayer;
flat out vec3 fireCentre;
flat out float fireTime;
#moj_import <minecraft:far_terrain.glsl>
#moj_import <minecraft:fire_eye_config.glsl>
