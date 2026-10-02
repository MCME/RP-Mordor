#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;

out vec4 lightColor;
out vec2 texCoord;
out vec2 texCoord2;
out vec3 Pos;
out float transition;

flat out int isCustom;
flat out int noshadow;
flat out int maxLod;
flat out int blendTexture;
flat out vec4 texRect;
// the fire eye (fire_eye_main.glsl)
flat out int fireLayer;
flat out vec3 fireCentre;
flat out float fireTime;
// BEGIN COMMENTED 1.21.4 BLOCK-LIGHTING VARYINGS
// flat out float baseBrightness;
// flat out float aoIntensity;
// flat out float customModelNormalShading;
// flat out float underShadowStrength;
// END COMMENTED 1.21.4 BLOCK-LIGHTING VARYINGS

#moj_import <objmc_tools.glsl>
#moj_import <fire_eye_config.glsl>

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    return texture(lightMap, clamp(uv / 256.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));
}

void main() {
    texCoord2 = UV0;
    transition = 0;
    isCustom = 0;
    noshadow = 0;
    maxLod = 0;
    blendTexture = 0;
    texRect = vec4(0.0);
    // BEGIN COMMENTED 1.21.4 BLOCK-LIGHTING DEFAULTS
    // baseBrightness = 1.0;
    // aoIntensity = 1.0;
    // customModelNormalShading = 1.0;
    // underShadowStrength = 1.0;
    // END COMMENTED 1.21.4 BLOCK-LIGHTING DEFAULTS
    Pos = Position + (ChunkPosition - CameraBlockPos) + CameraOffset;
    vertexColor = Color;
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    texCoord = UV0;
    
    //objmc
    #define BLOCK
    #moj_import <objmc_main.glsl>

    // the fire eye: GameTime is the day's fraction, restarting each day
    #define FIRE_MODELVIEW ModelViewMat
    #define FIRE_SECONDS (GameTime * 1200.0)
    #moj_import <fire_eye_main.glsl>

    gl_Position = ProjMat * ModelViewMat * vec4(Pos, 1.0);
    sphericalVertexDistance = fog_spherical_distance(Pos);
    cylindricalVertexDistance = fog_cylindrical_distance(Pos);
    // the fire eye is fogged as one thing, at its centre's distance - not by
    // its quad's far-flung corners, smeared across it
    if (fireLayer >= 0) {
        sphericalVertexDistance = fog_spherical_distance(fireCentre);
        cylindricalVertexDistance = fog_cylindrical_distance(fireCentre);
    }
}
