// 26.3's copy of assets/minecraft/shaders/include/mcme_hook_fragment_globals.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MCME_HOOK_FRAGMENT_GLOBALS_GLSL
#define MCME_MCME_HOOK_FRAGMENT_GLOBALS_GLSL
// RP-Mordor's own terrain features, hooked into the shader base's terrain
// fragment shaders - vanilla's and Sodium's (see mcme_hook_vertex_globals).
// The base's fluid.glsl, which the tar builds on, is imported, and so is its
// lava module, which Mordor turns on in its .mcme-shaders.json.

// the fire eye (fire_eye.glsl)
layout(location = 18) flat in int fireLayer;
layout(location = 19) flat in vec3 fireCentre;
layout(location = 20) flat in vec3 fireOrigin;
#define FIRE_ORIGIN fireOrigin
// the game's time, set in main: Sodium's own clock restarts with each region,
// and the sky, which draws the eye from afar, has only the game's
float fireTime = 0.0;
#include <minecraft:far_terrain.glsl>
#include <minecraft:fire_eye_config.glsl>
#include <minecraft:fire_eye.glsl>

// the tar
#include <minecraft:mordor_fluid.glsl>
#include <minecraft:tar_config.glsl>
#include <minecraft:tar.glsl>
#endif
