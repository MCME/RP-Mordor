// RP-Mordor's part of Distant Horizons' fog shader (distanthorizons:shaders/
// fog/gl/fog.frag), which imports it after declaring its uniforms: how much
// of the fire eye and its glow covers each LOD, as mordor_dh_terrain.glsl
// paints them there.

uniform ivec3 uMcmeCameraBlock;
uniform vec3 uMcmeCameraFrac;
uniform float uMcmeTime;

// the fire eye: only the eye from fireColor(), its glow from fireGlowLight()
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

// How much of the eye and its glow cover the LOD at view (relative to the
// camera), 0 to 1, as mordor_dh_terrain.glsl's applyFireEye paints them
// there - the glow by its strength; sets fireCentre. DH bends the terrain with
// the earth's curvature where set; the eye here isn't.
float mcmeFireEyeCover(vec3 view)
{
    fireCentre = vec3(FIRE_EYE_BLOCK - uMcmeCameraBlock) + 0.5 - uMcmeCameraFrac;
    float fireDistance = length(fireCentre);
    float shown = fireHandover(fireDistance);
    if (shown <= 0.0) return 0.0;
    fireRay = normalize(view);
    float viewDist = length(view);
    // its glow, as over the sky: none in front of the ball, all of it
    // FIRE_GLOW_DEPTH radii behind
    vec3 glow = fireGlowLight(fireRay, fireCentre) * shown
              * smoothstep(fireDistance - FIRE_RADIUS, fireDistance + FIRE_RADIUS * FIRE_GLOW_DEPTH, viewDist);
    float cover = max(glow.r, max(glow.g, glow.b));
    // the eye, where the ray passes near enough to meet it
    vec3 from = -fireCentre / FIRE_RADIUS;
    float pass = length(from + fireRay * max(dot(-from, fireRay), 0.0));
    if (pass < max(FIRE_EYE_WIDTH, FIRE_CORONA) * 1.05)
    {
        fireTime = uMcmeTime;
        vec4 eye = fireColor();
        float behind = smoothstep(fireDistance - FIRE_RADIUS * 1.2, fireDistance - FIRE_RADIUS * 0.7, viewDist);
        cover = max(cover, eye.a * behind * shown);
    }
    return clamp(cover, 0.0, 1.0);
}
