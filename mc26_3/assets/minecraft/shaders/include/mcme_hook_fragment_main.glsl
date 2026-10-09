// 26.3's copy of assets/minecraft/shaders/include/mcme_hook_fragment_main.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MCME_HOOK_FRAGMENT_MAIN_GLSL
#define MCME_MCME_HOOK_FRAGMENT_MAIN_GLSL
// The base has told which fluid the face is (fluid) and where on it
// (fluidHere), and drawn its water and its lava module.
// tar: lit and shaded as any block
if (fluid == TAR && fireLayer < 0) {
    color = vec4(tarColor(fluidHere, MCME_SECONDS, shore) * vertexColor.rgb * lightColor.rgb, 1.0);
}
// the fire eye: its own light, no shading, no light map. With a distant
// terrain mod the sky draws it from FIRE_HANDOVER on (core/sky.fsh), where
// this block can no longer be: it hands over, and past that costs nothing
if (fireLayer >= 0) {
    float fireHanded = farTerrain(MCME_FOG_START) ? fireHandover(length(fireCentre)) : 0.0;
    if (fireHanded >= 1.0) discard;
    fireTime = MCME_SECONDS;
    color = fireColor();
    color.a *= 1.0 - fireHanded;
    if (color.a <= 0.0) discard;              // only what's fully gone
}
#endif
