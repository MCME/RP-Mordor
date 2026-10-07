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

#moj_import <minecraft:mordor_dh_clouds.glsl>

void main()
{
    fragColor = fColor;
    mcmeDhCloud(fragColor);
}
