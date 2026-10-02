#version 330

// Vanilla 26.2's sky fragment shader, with the fire eye painted onto it where
// its block can't be drawn: past FIRE_HANDOVER, when a distant terrain mod
// (Distant Horizons, Voxy) draws the world out there. The sky is behind
// everything, so what is nearer - terrain, the mod's terrain, the clouds -
// covers it, as it should. Without one there is nothing out there, and no
// eye either.

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec3 skyDirection;

out vec4 fragColor;

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

void main() {
    fragColor = apply_fog(ColorModulator, sphericalVertexDistance, cylindricalVertexDistance, 0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd, FogColor);

    if (farTerrain(FogRenderDistanceStart)) {
        // relative to the camera
        fireCentre = vec3(FIRE_EYE_BLOCK - CameraBlockPos) + 0.5 + CameraOffset;
        float shown = fireHandover(length(fireCentre));
        if (shown > 0.0) {
            fireTime = GameTime * 1200.0;
            fireRay = normalize(skyDirection);
            // the eye, where the ray passes near enough to meet it
            vec3 from = -fireCentre / FIRE_RADIUS;
            float pass = length(from + fireRay * max(dot(-from, fireRay), 0.0));
            if (pass < max(FIRE_EYE_WIDTH, FIRE_CORONA) * 1.05) {
                vec4 eye = fireColor();
                fragColor.rgb = mix(fragColor.rgb, eye.rgb, eye.a * shown);
            }
            // its glow, over the sky as the block's glow is
            vec3 glow = fireGlowLight(fireRay, fireCentre) * shown;
            fragColor.rgb = glow + fragColor.rgb * (1.0 - max(glow.r, max(glow.g, glow.b)));
        }
    }
}
