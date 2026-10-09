// 26.3's copy of assets/minecraft/shaders/include/mcme_hook_vertex_globals.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MCME_HOOK_VERTEX_GLOBALS_GLSL
#define MCME_MCME_HOOK_VERTEX_GLOBALS_GLSL
// RP-Mordor's own terrain features, hooked into the shader base's terrain
// vertex shaders - vanilla's and Sodium's (ResourcePackScripts/shaderBase,
// docs/shader-base.md).

// the fire eye (fire_eye_main.glsl)
layout(location = 18) flat out int fireLayer;
layout(location = 19) flat out vec3 fireCentre;
layout(location = 20) flat out vec3 fireOrigin;
float fireTime;     // (the fragment shader keeps its own: the game's, everywhere)
#include <minecraft:far_terrain.glsl>
#include <minecraft:fire_eye_config.glsl>
#endif
