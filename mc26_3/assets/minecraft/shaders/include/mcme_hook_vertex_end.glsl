// 26.3's copy of assets/minecraft/shaders/include/mcme_hook_vertex_end.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MCME_HOOK_VERTEX_END_GLSL
#define MCME_MCME_HOOK_VERTEX_END_GLSL
// the fire eye is fogged as one thing, at its centre's distance - not by its
// quad's far-flung corners, smeared across it
if (fireLayer >= 0) {
    MCME_FOG_DISTANCE(fireCentre);
}
#endif
