// RP-Mordor's part of Voxy's LOD terrain fragment shader (voxy:lod/gl46/
// quads.frag). Voxy reads its shaders from its own jar: MCME's mod patches
// this file in as they load, and gives it mcmeLodPoint (the fragment's place,
// from Voxy's baseSectionPos * 32), mcmeLodId (its model's customId, flat,
// with MCME_VOXY_LAVA_BIT for lava) and lightSampler (the game's lightmap,
// with MCME's clock). It calls mcmeVoxyBegin() first in main(), then
// mcmeVoxyTerrain() on Voxy's colour without a shader pack, or with one
// mcmeVoxyShaderPack() on the colour the pack gets.

// lava, as the resource pack's terrain shaders draw it: still, as Voxy's
// LODs don't say which way it flows (not in the Lite zip)
#moj_import <minecraft:mcme_lite.glsl>
#ifndef MCME_LITE
#moj_import <minecraft:mcme_clock.glsl>
#moj_import <minecraft:fluid.glsl>
#moj_import <minecraft:lava_config.glsl>
#moj_import <minecraft:lava.glsl>

// set on lava only (mcmeVoxyBegin), which alone reads it: the start keeps drivers from warning
FluidFrame mcmeVoxyHere = FluidFrame(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0), vec2(0.0));

bool mcmeVoxyIsLava()
{
    return (mcmeLodId & MCME_VOXY_LAVA_BIT) != 0u;
}
#endif

// where a lava fragment is, taken before anything breaks derivatives. Only
// lava's: mcmeLodId is flat, the same over every fragment of a quad, so its
// fragments take derivatives together
void mcmeVoxyBegin()
{
#ifndef MCME_LITE
    if (!mcmeVoxyIsLava()) return;
    // the world's place, mod 64 as the terrain's: baseSectionPos counts 32 blocks
    vec3 world = mcmeLodPoint + vec3((baseSectionPos & 1) << 5);
    mcmeVoxyHere = fluidFrame(world, mcmeLodPoint - cameraSubPos, vec2(0.0));
#endif
}

// lava's look, on lava: its own light, its sides a little darker, as the game shades them
void mcmeVoxyLava(inout vec4 colour)
{
#ifndef MCME_LITE
    if (!mcmeVoxyIsLava()) return;
    float shade = fluidNormal(mcmeVoxyHere).y > 0.5 ? 1.0 : mix(1.0, 0.7, LAVA_SHADING);
    colour.rgb = lavaColor(LAVA_STILL, mcmeVoxyHere, mcmeClockSeconds(lightSampler)) * shade;
#endif
}

// MCME's part of the terrain's colour, after Voxy's own
void mcmeVoxyTerrain(inout vec4 colour)
{
    mcmeVoxyLava(colour);
}

// the colour a shader pack samples: lava's look, for it to light as its lava
void mcmeVoxyShaderPack(inout vec4 colour)
{
    mcmeVoxyLava(colour);
}
