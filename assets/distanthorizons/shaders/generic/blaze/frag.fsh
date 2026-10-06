#version 330
// needed for "layout(location = 0)" required as as of MC 26.3
#extension GL_ARB_separate_shader_objects : require

// Distant Horizons 3.3.3's fragment shader for its generic objects - its
// clouds among them (RP-Mordor: an override, kept to DH's own). Over the fire
// eye itself - its ball, flames and almond - one opens up, so the eye shows
// through: it burns at the top of the world, above the clouds, and they would
// hide it most of the time. Round that, the eye's glow lights them.

layout(location = 0) in vec4 fColor;
layout(location = 1) in vec3 fRelative;
layout(location = 2) flat in vec3 fEye;

layout(location = 0) out vec4 fragColor;

#moj_import <minecraft:far_terrain.glsl>
#moj_import <minecraft:fire_eye_config.glsl>
#define FIRE_NO_GLOW
int fireLayer = 0;
vec3 fireCentre = vec3(0.0);
float fireTime = 0.0;
vec3 fireRay = vec3(0.0, 0.0, -1.0);
#define Pos fireRay
#moj_import <minecraft:fire_eye.glsl>
#undef Pos

void main()
{
    fragColor = fColor;
    float eyeDistance = length(fEye);
    vec3 ray = normalize(fRelative);
    // the eye's glow on the cloud, wherever it reaches - behind the camera
    // too, when close: cut off with the hole, its edge drew a line across the sky
    vec3 glow = fireGlowLight(ray, fEye) * 0.6;
    fragColor.rgb = glow + fragColor.rgb * (1.0 - max(glow.r, max(glow.g, glow.b)));
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
