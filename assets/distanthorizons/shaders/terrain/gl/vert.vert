#version 330 core

// Distant Horizons 3.3.3's LOD terrain vertex shader, for its OpenGL renderer - which it uses
// whenever Iris is installed (RP-Mordor: an override, kept to DH's own). DH
// reads it only with MCME's mod installed, which loads DH's OpenGL shaders
// from resource packs and gives this one the camera's position and the time. The same as the
// override for DH's Blaze3D renderer, in ../blaze.

#moj_import <minecraft:fire_eye_config.glsl>

// from MCME's mod: the camera's block and where in it, and the time, in
// seconds into the day
uniform ivec3 uMcmeCameraBlock;
uniform vec3 uMcmeCameraFrac;
uniform float uMcmeTime;

in uvec4 vPosition;
in vec4 color;
// x: iris material id, y: face normal index, zw: block texture tile id (little endian)
in uvec4 irisData;

out vec4 vPos;
out vec4 vertexColor;
out vec3 vertexWorldPos;
out float vertexYPos;
// block-grid position used to generate texture UVs, fract() of this repeats per block
out vec3 vBlockPos;
flat out uint vNormalIndex;
flat out uint vTextureTileId;
// the eye's centre, relative to the camera, and the time, in seconds
flat out vec3 vFireCentre;
flat out float vFireTime;
// lava (lava.glsl): the LOD's material, and its position, mod 64 blocks
flat out uint vMaterial;
out vec3 vLavaWorld;

uniform bool uIsWhiteWorld;

uniform mat4 uCombinedMatrix;
uniform vec3 uModelOffset;
uniform float uWorldYOffset;

uniform sampler2D uLightMap;
uniform float uMircoOffset;

uniform float uEarthRadius;

uniform float uFrameMod8;
uniform float uViewWidth;
uniform float uViewHeight;


vec2 jitterOffsets[8] = vec2[8](
    vec2( 0.125, -0.375),
    vec2(-0.125,  0.375),
    vec2( 0.625,  0.125),
    vec2( 0.375, -0.625),
    vec2(-0.625,  0.625),
    vec2(-0.875, -0.125),
    vec2( 0.375, -0.875),
    vec2( 0.875,  0.875)
);

vec2 TAAJitter(vec2 coord, float w)
{
    vec2 offset = jitterOffsets[int(uFrameMod8)] * (w / vec2(uViewWidth, uViewHeight));
    return coord + offset;
}

/** 
 * Vertex Shader
 * 
 * author: James Seibel
 * author: TomTheFurry
 * author: stduhpf
 * updated: coolGi
 *
 * version: 2025-12-22
 */
void main()
{
    vPos = vPosition; // This is so it can be passed to the fragment shader
    
    vBlockPos = vec3(vPosition.xyz);
    vNormalIndex = irisData.y;
    vTextureTileId = irisData.z | (irisData.w << 8u);
    
    vertexWorldPos = vPosition.xyz + uModelOffset;
    
    vertexYPos = vPosition.y + uWorldYOffset;
    
    uint meta = vPosition.a;
    
    uint mirco = (meta & 0xFF00u) >> 8u; // mirco offset which is a xyz 2bit value
    // 0b00 = no offset
    // 0b01 = positive offset
    // 0b11 = negative offset
    // format is: 0b00zzyyxx
    float mx = (mirco & 1u)!=0u ? uMircoOffset : 0.0;
    mx = (mirco & 2u)!=0u ? -mx : mx;
    //float my = (mirco & 4u)!=0u ? uMircoOffset : 0.0;
    //my = (mirco & 8u)!=0u ? -my : my;
    float mz = (mirco & 16u)!=0u ? uMircoOffset : 0.0;
    mz = (mirco & 32u)!=0u ? -mz : mz;
    
    vertexWorldPos.x += mx;
    //vertexWorldPos.y += my;
    vertexWorldPos.z += mz;
    
    // apply the earth curvature if needed
    if (uEarthRadius < -1.0f || uEarthRadius > 1.0f)
    {
        // vertex transformation logic - stduhpf
        float localRadius = uEarthRadius + vertexYPos;
        float phi = length(vertexWorldPos.xz) / localRadius;
        vertexWorldPos.y += (cos(phi) - 1.0) * localRadius;
        vertexWorldPos.xz = vertexWorldPos.xz * sin(phi) / phi;
    }
    
    uint lights = meta & 0xFFu;
    float skyLight = (float(lights/16u)+0.5) / 16.0;
    float blockLight = (mod(float(lights), 16.0)+0.5) / 16.0;
    vertexColor = vec4(texture(uLightMap, vec2(skyLight, blockLight)).xyz, 1.0);
    
    if (!uIsWhiteWorld)
    {
        vertexColor *= color;
    }
    
    // the eye, as the terrain round it: bent with the earth's curvature too
    vFireCentre = vec3(FIRE_EYE_BLOCK - uMcmeCameraBlock) + 0.5 - uMcmeCameraFrac;
    if (uEarthRadius < -1.0f || uEarthRadius > 1.0f)
    {
        float localRadius = uEarthRadius + float(FIRE_EYE_BLOCK.y) + 0.5;
        float phi = length(vFireCentre.xz) / localRadius;
        vFireCentre.y += (cos(phi) - 1.0) * localRadius;
        vFireCentre.xz = vFireCentre.xz * sin(phi) / max(phi, 1.0e-6);
    }
    vFireTime = uMcmeTime;

    // lava: DH's material for it (EDhApiBlockMaterial.LAVA is 6), and where
    // the vertex is, its LOD's place taken mod 64 - not the vertex's, which
    // would wrap across a face. (The model offset is relative to the camera.)
    vMaterial = irisData.x;
    ivec3 model = ivec3(round(uModelOffset + vec3(uMcmeCameraBlock) + uMcmeCameraFrac));
    vLavaWorld = vec3(vPosition.xyz) + vec3(model & 63);

    gl_Position = uCombinedMatrix * vec4(vertexWorldPos, 1.0);

    // -1 if TAA is diabled
    if (uFrameMod8 > 0)
    {
        // jittering the model around is necessary to smooth out TAA properly
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    }
}
