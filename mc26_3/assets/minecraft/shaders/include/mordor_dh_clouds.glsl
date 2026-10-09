// 26.3's copy of assets/minecraft/shaders/include/mordor_dh_clouds.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_MORDOR_DH_CLOUDS_GLSL
#define MCME_MORDOR_DH_CLOUDS_GLSL
// RP-Mordor's part of Distant Horizons' generic-object fragment shader (its
// clouds among them), shared by its overrides for DH's two renderers
// (distanthorizons:shaders/generic/blaze/frag.fsh and gl/instanced/frag.frag),
// which import it after declaring their inputs - fRelative, fEye - and call
// mcmeDhCloud() in main(). Over the fire eye itself the cloud opens up, so the
// eye shows through; round that, the eye's glow lights it.

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

void mcmeDhCloud(inout vec4 color)
{
    float eyeDistance = length(fEye);
    vec3 ray = normalize(fRelative);
    // the eye's glow on the cloud, wherever it reaches - behind the camera
    // too, when close: cut off with the hole, its edge drew a line across the sky
    vec3 glow = fireGlowLight(ray, fEye) * 0.6;
    color.rgb = glow + color.rgb * (1.0 - max(glow.r, max(glow.g, glow.b)));
    // the eye is painted on what lies behind it - the sky, the LODs' terrain -
    // so a cloud covers it wherever it is, even beyond it: the hole opens
    // over it whatever the cloud's distance, as long as it's ahead - well
    // ahead: nearly square to it, below, the plane is crossed nowhere (and
    // dividing by almost nothing gave NaN, which cut a line through the clouds)
    vec3 toEye = fEye / eyeDistance;
    if (dot(toEye, ray) < 0.2) return;
    // where the ray crosses the plane through the eye's centre facing the
    // camera, in radii from it, along its view's right and up; the almond,
    // fixed north-south, as wide as it looks from here. (Not where the ray
    // passes nearest the centre: for rays nearly square to it that is by the
    // camera, which flattened onto this plane lands on the eye - and opened a
    // strip through the clouds overhead)
    vec3 right = normalize(cross(toEye, vec3(0.0, 1.0, 0.0)) + vec3(1.0e-5, 0.0, 0.0));
    vec3 up = cross(right, toEye);
    vec3 off = (ray * (eyeDistance / dot(toEye, ray)) - fEye) / FIRE_RADIUS;
    vec2 q = vec2(dot(off, right), dot(off, up));
    float wide = max(FIRE_CORONA, FIRE_EYE_WIDTH * abs(right.z));
    float tall = max(FIRE_CORONA, FIRE_EYE_HEIGHT);
    float inside = length(q / vec2(wide, tall));
    // the hole, its edge dithered, so it needs no blending
    float open = 1.0 - smoothstep(0.85, 1.15, inside);
    ivec2 p = ivec2(gl_FragCoord.xy) & 3;
    float dither = (float((p.x ^ p.y) * 4 + p.y) + 0.5) / 16.0;
    if (open > dither) discard;
}
#endif
