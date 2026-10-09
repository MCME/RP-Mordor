#version 330
// 26.3's copy of assets/distanthorizons/shaders/generic/blaze/vert.vsh, translated by ResourcePackScripts' shader_base.py: don't edit it.
// needed for "layout(location = 0)" required as as of MC 26.3
#extension GL_ARB_separate_shader_objects : require

// Distant Horizons 3.3.3's vertex shader for its generic objects - its clouds
// among them (RP-Mordor: an override, kept to DH's own), passing on where the
// point and the fire eye are, relative to the camera, for frag.fsh to let the
// eye show through the clouds in front of it and light them with its glow.

#include <minecraft:fire_eye_config.glsl>

layout(location = 0) in vec3 vPosition;
layout(location = 1) in vec4 aColor; // RGBA_FLOAT_COLOR
layout(location = 2) in uint aMaterial; // IRIS_MATERIAL

layout (std140) uniform vertUniformBlock
{
    ivec3 uOffsetChunk;
    vec3 uOffsetSubChunk;
    ivec3 uCameraPosChunk;
    vec3 uCameraPosSubChunk;

    mat4 uProjectionMvm;
    int uSkyLight;
    int uBlockLight;

    float uNorthShading;
    float uSouthShading;
    float uEastShading;
    float uWestShading;
    float uTopShading;
    float uBottomShading;
};

uniform sampler2D uLightMap;

layout(location = 0) out vec4 fColor;
layout(location = 1) out vec3 fRelative;
layout(location = 2) flat out vec3 fEye;

void main()
{
    vec3 aScale = vec3(1);
    
    // aTranslate - moves the vertex to the boxGroup's relative position
    // uOffset - moves the vertex to the boxGroup's world position
    // uCameraPos - moves the vertex into camera space
    vec3 trans = (uOffsetChunk - uCameraPosChunk) * 16.0f;
    // separate float and int values are to fix percission loss at extreme distances from the origin (IE 10,000,000+)
    // luckily large translate values minus large cameraPos generally equal values that cleanly fit in a float
    trans += (uOffsetSubChunk - uCameraPosSubChunk);
    
    // combination translation and scaling matrix
    mat4 transform = mat4(
        aScale.x, 0.0,      0.0,      0.0,
        0.0,      aScale.y, 0.0,      0.0,
        0.0,      0.0,      aScale.z, 0.0,
        trans.x,  trans.y,  trans.z,  1.0
    );
    
    gl_Position = uProjectionMvm * transform * vec4(vPosition, 1.0);
    fRelative = vPosition + trans;
    fEye = vec3((FIRE_EYE_BLOCK >> 4) - uCameraPosChunk) * 16.0 + (vec3(FIRE_EYE_BLOCK & 15) + 0.5 - uCameraPosSubChunk);

    float blockLight = (float(uBlockLight)+0.5) / 16.0;
    float skyLight = (float(uSkyLight)+0.5) / 16.0;
    vec4 lightColor = vec4(texture(uLightMap, vec2(blockLight, skyLight)).xyz, 1.0);
    
    
    fColor = lightColor * aColor;

    int vertexIndex;
    #ifdef VULKAN
    vertexIndex = gl_VertexIndex % 24;
    #else
    vertexIndex = gl_VertexID % 24;
    #endif
    
    // apply directional shading
    if (vertexIndex >= 0 && vertexIndex < 4) { fColor.rgb *= uNorthShading; }
    else if (vertexIndex >= 4 && vertexIndex < 8) { fColor.rgb *= uSouthShading; }
    else if (vertexIndex >= 8 && vertexIndex < 12) { fColor.rgb *= uWestShading; }
    else if (vertexIndex >= 12 && vertexIndex < 16) { fColor.rgb *= uEastShading; }
    else if (vertexIndex >= 16 && vertexIndex < 20) { fColor.rgb *= uBottomShading; }
    else if (vertexIndex >= 20 && vertexIndex < 24) { fColor.rgb *= uTopShading; }

}
