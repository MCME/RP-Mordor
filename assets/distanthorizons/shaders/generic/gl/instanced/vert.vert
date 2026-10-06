#version 330 core

// Distant Horizons 3.3.3's vertex shader for its generic objects - its clouds among them, for its OpenGL renderer - which it uses
// whenever Iris is installed (RP-Mordor: an override, kept to DH's own). DH
// reads it only with MCME's mod installed, which loads DH's OpenGL shaders
// from resource packs and gives this one nothing more. The same as the
// override for DH's Blaze3D renderer, in ../blaze.
// Passes on where the point and the fire eye are, relative to the camera, for
// frag.frag to let the eye show through clouds in front of it.

#moj_import <minecraft:fire_eye_config.glsl>

layout (location = 1) in vec4 aColor;
layout (location = 2) in vec3 aScale;
layout (location = 3) in ivec3 aTranslateChunk;
layout (location = 4) in vec3 aTranslateSubChunk;
layout (location = 5) in int aMaterial;

uniform ivec3 uOffsetChunk;
uniform vec3 uOffsetSubChunk;
uniform ivec3 uCameraPosChunk;
uniform vec3 uCameraPosSubChunk;

uniform mat4 uProjectionMvm;
uniform int uSkyLight;
uniform int uBlockLight;
uniform sampler2D uLightMap;

uniform float uNorthShading;
uniform float uSouthShading;
uniform float uEastShading;
uniform float uWestShading;
uniform float uTopShading;
uniform float uBottomShading;


in vec3 vPosition;

out vec4 fColor;
out vec3 fRelative;
flat out vec3 fEye;

void main()
{
    // aTranslate - moves the vertex to the boxGroup's relative position
    // uOffset - moves the vertex to the boxGroup's world position
    // uCameraPos - moves the vertex into camera space
    vec3 trans = (aTranslateChunk + uOffsetChunk - uCameraPosChunk) * 16.0f;
    // separate float and int values are to fix percission loss at extreme distances from the origin (IE 10,000,000+)
    // luckily large translate values minus large cameraPos generally equal values that cleanly fit in a float
    trans += (aTranslateSubChunk + uOffsetSubChunk - uCameraPosSubChunk);
    
    // combination translation and scaling matrix
    mat4 transform = mat4(
        aScale.x, 0.0,      0.0,      0.0,
        0.0,      aScale.y, 0.0,      0.0,
        0.0,      0.0,      aScale.z, 0.0,
        trans.x,  trans.y,  trans.z,  1.0
    );
    
    gl_Position = uProjectionMvm * transform * vec4(vPosition, 1.0);
    fRelative = (transform * vec4(vPosition, 1.0)).xyz;
    fEye = vec3((FIRE_EYE_BLOCK >> 4) - uCameraPosChunk) * 16.0 + (vec3(FIRE_EYE_BLOCK & 15) + 0.5 - uCameraPosSubChunk);

    float blockLight = (float(uBlockLight)+0.5) / 16.0;
    float skyLight = (float(uSkyLight)+0.5) / 16.0;
    vec4 lightColor = vec4(texture(uLightMap, vec2(blockLight, skyLight)).xyz, 1.0);
    
    
    fColor = lightColor * aColor;
    
    // apply directional shading
    if (gl_VertexID >= 0 && gl_VertexID < 4) { fColor.rgb *= uNorthShading; }
    else if (gl_VertexID >= 4 && gl_VertexID < 8) { fColor.rgb *= uSouthShading; }
    else if (gl_VertexID >= 8 && gl_VertexID < 12) { fColor.rgb *= uWestShading; }
    else if (gl_VertexID >= 12 && gl_VertexID < 16) { fColor.rgb *= uEastShading; }
    else if (gl_VertexID >= 16 && gl_VertexID < 20) { fColor.rgb *= uBottomShading; }
    else if (gl_VertexID >= 20 && gl_VertexID < 24) { fColor.rgb *= uTopShading; }
    
}
