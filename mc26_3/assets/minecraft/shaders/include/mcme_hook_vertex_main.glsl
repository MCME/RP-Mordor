// 26.3's copy of assets/minecraft/shaders/include/mcme_hook_vertex_main.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MCME_HOOK_VERTEX_MAIN_GLSL
#define MCME_MCME_HOOK_VERTEX_MAIN_GLSL
// the fire eye. Its clock: under vanilla GameTime, the day's fraction; under
// Sodium milliseconds since its region was made, so it restarts when the
// region is
#define FIRE_MODELVIEW MCME_MODELVIEW
#ifdef MCME_PROJECTION
#define FIRE_PROJECTION MCME_PROJECTION
#endif
#define FIRE_SECONDS MCME_SECONDS
#include <minecraft:fire_eye_main.glsl>
#endif
