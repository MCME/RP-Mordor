#version 330
// needed for "layout(location = 0)" required as as of MC 26.3
#extension GL_ARB_separate_shader_objects : require

// Distant Horizons 3.3.2's fade from vanilla chunks into its LODs (RP-Mordor:
// an override, kept to DH's own), fading a vanilla pixel only into LOD
// terrain at about its distance - not into what the LODs show far behind it,
// where they lack what vanilla draws there: so the fire eye's block, which no
// LOD has, doesn't fade into the terrain behind it and vanish.

layout(location = 0) in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

uniform sampler2D uMcDepthTexture;
uniform sampler2D uCombinedMcDhColorTexture;

uniform sampler2D uDhDepthTexture;
uniform sampler2D uDhColorTexture;

layout (std140) uniform fragUniformBlock
{
    bool uOnlyRenderLods;
    
    float uStartFadeBlockDistance;
    float uEndFadeBlockDistance;
    float uMaxLevelHeight;
    
    // inverted model view matrix and projection matrix
    mat4 uDhInvMvmProj;
    mat4 uMcInvMvmProj;

    bool uIsMcReverseZDepth;
    bool uDepthIsZeroToPositiveOne;
};



/** 
 * this method is shared across several shaders,
 * if updated, make sure to update the other versions as well.
 */
vec3 calcViewPosition(float fragmentDepth, mat4 invMvmProj)
{
    // normalized device coordinates
    vec4 ndc = vec4(texCoord.xy, fragmentDepth, 1.0);
    if (uDepthIsZeroToPositiveOne)
    {
        // Z already in [0,1], don't remap
        ndc.xy = ndc.xy * 2.0 - 1.0;
    }
    else
    {
        // UV [0,1] -> NDC [-1,+1]
        ndc.xyz = ndc.xyz * 2.0 - 1.0;
    }

    vec4 eyeCoord = invMvmProj * ndc;
    return eyeCoord.xyz / eyeCoord.w;
}


/**
 * Used to fade out vanilla chunks so the transition
 * between DH and vanilla is smoother.
 */
void main() 
{
    // includes both the vanilla chunks as well as DH
    vec4 combinedMcDhColor = texture(uCombinedMcDhColorTexture, texCoord);
    // just the DH render pass
    vec4 dhColor = texture(uDhColorTexture, texCoord);
    
    // completely remove the MC render pass to only show LODs
    // useful for debugging/troubleshooting, but doesn't improve performance since MC is still rendering
    if (uOnlyRenderLods)
    {
        fragColor = dhColor;
        return;
    }
    
    
    // ignore anything that DH hasn't drawn to
    if (dhColor.a == 0.0f)
    {
        // if not done vanilla clouds will render incorrectly at night
        dhColor = combinedMcDhColor;
    }
    
    float mcFragmentDepth = texture(uMcDepthTexture, texCoord).r;
    float dhFragmentDepth = texture(uDhDepthTexture, texCoord).r;
    vec3 dhVertexWorldPos = calcViewPosition(dhFragmentDepth, uDhInvMvmProj);

    // we only want to fade vanilla rendered objects, not to the sky or LODs
    bool isGround;
    if (uIsMcReverseZDepth)
    {
        isGround = (mcFragmentDepth > 0);
    }
    else
    {
        // a fragment depth of "1" means the fragment wasn't drawn to
        isGround = (mcFragmentDepth < 1.0);
    }
    
	// this is a work around to prevent MC clouds rendering behind DH clouds
    if (dhVertexWorldPos.y > uMaxLevelHeight)
    {
        fragColor = vec4(combinedMcDhColor.rgb, 0.0);
    }
    else if (isGround)
    {
        // fade based on distance from the camera
        vec3 mcVertexWorldPos = calcViewPosition(mcFragmentDepth, uMcInvMvmProj);
        float mcFragmentDistance = length(mcVertexWorldPos.xzy);
        
        
        // Smoothly transition between combinedMcDhColor and uDhColorTexture
        // as the depth increases from the camera
        float fadeStep = smoothstep(uStartFadeBlockDistance, uEndFadeBlockDistance, mcFragmentDistance);
        // not into LOD terrain far behind it (where DH drew any)
        if (texture(uDhColorTexture, texCoord).a != 0.0)
        {
            float dhFragmentDistance = length(dhVertexWorldPos);
            fadeStep *= 1.0 - smoothstep(16.0, 32.0, dhFragmentDistance - mcFragmentDistance);
        }
        fragColor = mix(combinedMcDhColor, dhColor, fadeStep);
        fragColor.a = 1.0;
    }
    else
    {
        fragColor = vec4(combinedMcDhColor.rgb, 0.0);
    }
}

