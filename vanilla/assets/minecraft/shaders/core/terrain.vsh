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
// lava and water (fluid.glsl): the position, mod 64 blocks
out vec3 lavaWorld;
// water (water.glsl): each corner's brightness, for its shores
out vec4 waterLights;
out vec4 waterWeights;
// clouds and smoke (fog_volume.glsl): which, if any, this is, and its
// block's middle, relative to the camera and in the world mod 64
flat out int volumeKind;
flat out vec3 volumeCentre;
flat out vec3 volumeBlock;
// BEGIN COMMENTED 1.21.4 BLOCK-LIGHTING VARYINGS
// flat out float baseBrightness;
// flat out float aoIntensity;
// flat out float customModelNormalShading;
// flat out float underShadowStrength;
// END COMMENTED 1.21.4 BLOCK-LIGHTING VARYINGS

#moj_import <objmc_tools.glsl>
#moj_import <far_terrain.glsl>
#moj_import <fire_eye_config.glsl>
#moj_import <water_corner.glsl>
#moj_import <fog_block_config.glsl>
#moj_import <fog_volume.glsl>

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
    // lava: the vertex's place in its section, plus the section's position
    // mod 64 - as Sodium's shader gives it
    lavaWorld = Position + vec3(ChunkPosition & 63);
    waterCorner(gl_VertexID, Color.rgb, waterLights, waterWeights);
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

    // clouds and smoke: spread over their volumes
    #define VOLUME_MODELVIEW ModelViewMat
    #moj_import <fog_volume_main.glsl>

    gl_Position = ProjMat * ModelViewMat * vec4(Pos, 1.0);
    sphericalVertexDistance = fog_spherical_distance(Pos);
    cylindricalVertexDistance = fog_cylindrical_distance(Pos);
    // the fire eye is fogged as one thing, at its centre's distance - not by
    // its quad's far-flung corners, smeared across it
    if (fireLayer >= 0) {
        sphericalVertexDistance = fog_spherical_distance(fireCentre);
        cylindricalVertexDistance = fog_cylindrical_distance(fireCentre);
    }
    // a volume too, at its block's
    if (volumeKind > 0) {
        sphericalVertexDistance = fog_spherical_distance(volumeCentre);
        cylindricalVertexDistance = fog_cylindrical_distance(volumeCentre);
    }
}
