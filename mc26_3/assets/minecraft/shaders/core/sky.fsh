#version 330
// 26.3's copy of assets/minecraft/shaders/core/sky.fsh, translated by ResourcePackScripts' shader_base.py: don't edit it.
#extension GL_ARB_separate_shader_objects : require

// Vanilla 26.2's sky fragment shader, with the fire eye painted onto it where
// its block can't be drawn: past FIRE_HANDOVER, when a distant terrain mod
// (Distant Horizons, Voxy) draws the world out there. The sky is behind
// everything, so what is nearer - terrain, the mod's terrain, the clouds -
// covers it, as it should. Without one there is nothing out there, and no
// eye either.
//
// Meanwhile sky.vsh pulls the disc above down into a pyramid, so the eye can
// be painted below the horizon too. The sky itself is drawn as the disc drew
// it, with the fog distances its vertices gave; past its rim only the eye is,
// over the frame's clear colour - the fog colour - which shows there.

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:globals.glsl>

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 2) in vec3 skyDirection;
layout(location = 3) in float skyAbove;
layout(location = 4) flat in vec3 skyOrigin;

layout(location = 0) out vec4 fragColor;

// the fire eye: only the eye from fireColor(), its glow from fireGlowLight()
#include <minecraft:far_terrain.glsl>
#include <minecraft:fire_eye_config.glsl>
#include <minecraft:fire_eye_sky.glsl>
#define FIRE_NO_GLOW
int fireLayer = 0;
vec3 fireCentre = vec3(0.0);
float fireTime = 0.0;
vec3 firePoint = vec3(0.0, 0.0, -1.0);
#define Pos firePoint
#define FIRE_ORIGIN skyOrigin
#include <minecraft:fire_eye.glsl>
#undef Pos

void main() {
    if (!fireSkyPulled()) {
        fragColor = apply_fog(ColorModulator, sphericalVertexDistance, cylindricalVertexDistance, 0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd, FogColor);
        return;
    }

    // the view ray, from where the camera truly is: the pulled-down sky is
    // only a few blocks off, so from the camera's position - the view bobbing
    // moves the camera off it as the player walks - the eye would swing about
    // against the world
    firePoint = skyDirection;
    vec3 ray = normalize(skyDirection - skyOrigin);
    bool sky = true;
    if (skyAbove > 0.5) {
        float spherical, cylindrical;
        sky = fireSkyDisc(ray, spherical, cylindrical);
        fragColor = sky ? apply_fog(ColorModulator, spherical, cylindrical, 0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd, FogColor)
                        : vec4(FogColor.rgb, ColorModulator.a);
    } else {
        fragColor = apply_fog(ColorModulator, sphericalVertexDistance, cylindricalVertexDistance, 0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd, FogColor);
    }

    // relative to the camera
    fireCentre = vec3(FIRE_EYE_BLOCK - CameraBlockPos) + 0.5 + CameraOffset;
    // and dimmed by Distant Horizons' fog near the horizon, as the land round it
    float shown = fireHandover(length(fireCentre)) * (1.0 - fireSkyFog() * fireFogShare(fireCentre));
    fireTime = GameTime * 1200.0;
    bool painted = false;
    // the eye, where the ray passes near enough to meet it
    vec3 from = (skyOrigin - fireCentre) / FIRE_RADIUS;
    float pass = length(from + ray * max(dot(-from, ray), 0.0));
    if (pass < max(FIRE_EYE_WIDTH, FIRE_CORONA) * 1.05) {
        vec4 eye = fireColor();
        fragColor.rgb = mix(fragColor.rgb, eye.rgb, eye.a * shown);
        painted = eye.a * shown > 0.0;
    }
    // its glow, over the sky as the block's glow is
    vec3 glow = fireGlowLight(ray, fireCentre - skyOrigin) * shown;
    fragColor.rgb = glow + fragColor.rgb * (1.0 - max(glow.r, max(glow.g, glow.b)));
    // past the disc, the clear colour is left alone but for the eye
    if (!sky && !painted && max(glow.r, max(glow.g, glow.b)) <= 0.0) {
        discard;
    }
}
