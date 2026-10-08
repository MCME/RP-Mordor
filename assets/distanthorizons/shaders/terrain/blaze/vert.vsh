#version 330
// needed for "layout(location = 0)" required as as of MC 26.3
#extension GL_ARB_separate_shader_objects : require

// Distant Horizons 3.3.2's LOD terrain vertex shader (RP-Mordor: an override,
// kept to DH's own), passing on where the fire eye is and the time, for
// frag.fsh to paint it onto the terrain behind it, and what frag.fsh needs to
// draw lava as the resource pack's shaders do.

#moj_import <minecraft:fire_eye_config.glsl>
#moj_import <minecraft:mcme_clock.glsl>

layout(location = 0) in uvec3 vPosition;
layout(location = 1) in uint meta; // contains light and micro-offset data
layout(location = 2) in vec4 vColor;
layout(location = 3) in uint irisMaterial;
layout(location = 4) in uint irisNormal;
layout(location = 5) in uint textureTile; // block texture tile id, 0 = flat color

// order matters, this must match the fragment shader's inputs
layout(location = 0) out vec3 vPos;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) out vec3 vertexWorldPos;
// block-grid position used to generate texture UVs, fract() of this repeats per block
layout(location = 3) out vec3 vBlockPos;
layout(location = 4) flat out uint vNormalIndex;
layout(location = 5) flat out uint vTextureTileId;
// the eye's centre, relative to the camera, and the time, in seconds
layout(location = 7) flat out vec3 vFireCentre;
layout(location = 8) flat out float vFireTime;
// lava (lava.glsl): the LOD's material, and its position, mod 64 blocks
layout(location = 9) flat out uint vMaterial;
layout(location = 10) out vec3 vLavaWorld;

layout (std140) uniform vertUniqueUniformBlock
{
    vec3 uModelOffset;
};

layout (std140) uniform vertSharedUniformBlock 
{ 
    bool uIsWhiteWorld;
    
    float uWorldYOffset;
    float uMircoOffset;
    float uEarthRadius;
    
    float uFrameMod8;
    float uViewWidth;
    float uViewHeight;

    vec3 uCameraPos;
    mat4 uCombinedMatrix;
};

uniform sampler2D uLightMap;

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
 * LOD terrain Vertex Shader
 */
void main()
{
    vPos = vPosition; // This is so it can be passed to the fragment shader
    
    vBlockPos = vec3(vPosition.xyz);
    vNormalIndex = uint(irisNormal);
    vTextureTileId = textureTile;
    
    vertexWorldPos = vPosition.xyz + (uModelOffset - uCameraPos);
    
    float vertexYPos = vPosition.y + uWorldYOffset;
    
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
        vertexColor *= vColor;
    }
    
    // the eye, as the terrain round it: bent with the earth's curvature too
    vFireCentre = vec3(FIRE_EYE_BLOCK) + 0.5 - uCameraPos;
    if (uEarthRadius < -1.0f || uEarthRadius > 1.0f)
    {
        float localRadius = uEarthRadius + float(FIRE_EYE_BLOCK.y) + 0.5;
        float phi = length(vFireCentre.xz) / localRadius;
        vFireCentre.y += (cos(phi) - 1.0) * localRadius;
        vFireCentre.xz = vFireCentre.xz * sin(phi) / max(phi, 1.0e-6);
    }
    vFireTime = mcmeClockSeconds(uLightMap);

    // lava: DH's material for it (EDhApiBlockMaterial.LAVA is 6), and where
    // the vertex is, its LOD's place taken mod 64 - not the vertex's, which
    // would wrap across a face
    vMaterial = irisMaterial;
    vLavaWorld = vec3(vPosition) + mod(uModelOffset, 64.0);

    gl_Position = uCombinedMatrix * vec4(vertexWorldPos, 1.0);
    
    // -1 if TAA is diabled
    if (uFrameMod8 > 0)
    {
		// jittering the model around is necessary to smooth out TAA properly
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    }
}
