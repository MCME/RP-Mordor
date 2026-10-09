// 26.3's copy of assets/minecraft/shaders/include/mordor_dh_terrain.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MORDOR_DH_TERRAIN_GLSL
#define MCME_MORDOR_DH_TERRAIN_GLSL
// RP-Mordor's part of Distant Horizons' LOD terrain fragment shader, shared
// by its overrides for DH's two renderers (distanthorizons:shaders/terrain/
// blaze/frag.fsh and gl/frag.frag), which import it after declaring their
// inputs - vertexWorldPos, vFireCentre, vFireTime, vMaterial, vNormalIndex -
// and call mcmeDhTerrain() last in main().

// the fire eye: only the eye from fireColor(), its glow from fireGlowLight()
#include <minecraft:far_terrain.glsl>
#include <minecraft:fire_eye_config.glsl>
#define FIRE_NO_GLOW
int fireLayer = 0;
vec3 fireCentre = vec3(0.0);
float fireTime = 0.0;
vec3 fireRay = vec3(0.0, 0.0, -1.0);
#define Pos fireRay
#include <minecraft:fire_eye.glsl>
#undef Pos

// lava, as the resource pack's terrain shaders draw it: still, as DH's LODs
// don't say which way it flows
#include <minecraft:mcme_lite.glsl>
#include <minecraft:fluid.glsl>
#include <minecraft:lava_config.glsl>
#include <minecraft:lava.glsl>
#include <minecraft:water_config.glsl>

// the eye and its glow over this terrain, if it lies behind the eye's front:
// on water and the like as well as on what is under them, so that what DH
// blends over its LODs (its see-through ones, drawn after) leaves the eye
// as it is - the eye mixed into both, and the glow lighting both, blend back
// to them
void applyFireEye(inout vec4 color, float viewDist)
{
    fireCentre = vFireCentre;
    float fireDistance = length(fireCentre);
    float shown = fireHandover(fireDistance);
    if (shown <= 0.0) return;
    fireTime = vFireTime;
    fireRay = normalize(vertexWorldPos);
    // the eye, where the ray passes near enough to meet it
    vec3 from = -fireCentre / FIRE_RADIUS;
    float pass = length(from + fireRay * max(dot(-from, fireRay), 0.0));
    if (pass < max(FIRE_EYE_WIDTH, FIRE_CORONA) * 1.05)
    {
        vec4 eye = fireColor();
        float behind = smoothstep(fireDistance - FIRE_RADIUS * 1.2, fireDistance - FIRE_RADIUS * 0.7, viewDist);
        color.rgb = mix(color.rgb, eye.rgb, eye.a * behind * shown);
    }
    // its glow, as over the sky: none in front of the ball, all of it
    // FIRE_GLOW_DEPTH radii behind
    vec3 glow = fireGlowLight(fireRay, fireCentre) * shown
              * smoothstep(fireDistance - FIRE_RADIUS, fireDistance + FIRE_RADIUS * FIRE_GLOW_DEPTH, viewDist);
    color.rgb = glow + color.rgb * (1.0 - max(glow.r, max(glow.g, glow.b)));
}

// MCME's part of the terrain's colour, after DH's own: lava and water as the
// resource pack draws them (not in the Lite zip), then the eye
void mcmeDhTerrain(inout vec4 color, FluidFrame fluidHere, float viewDist)
{
#ifndef MCME_LITE
    // lava: its own light, its sides a little darker, as DH shades them
    if (vMaterial == 6u)
    {
        color.rgb = lavaColor(LAVA_STILL, fluidHere, vFireTime) * (vNormalIndex == 1u ? 1.0 : mix(1.0, 0.7, LAVA_SHADING));
    }

    // water: about as murky as MCME's water close up, and brightened as it
    // is (water.glsl's waterMurky), so that looked straight down on it would
    // be the biome's colour
    if (vMaterial == 12u)
    {
        color.rgb *= mix(1.0, WATER_MURK_SHADE, 0.8) / mix(1.0, WATER_MURK_SHADE, 1.0 - exp(-WATER_MURK_DEPTH / WATER_MURK_CLEAR));
    }
#endif

    applyFireEye(color, viewDist);
}
#endif
