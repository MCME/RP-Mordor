#version 330 core

// Distant Horizons 3.3.3's fragment shader for its generic objects - its clouds among them, for its OpenGL renderer - which it uses
// whenever Iris is installed (RP-Mordor: an override, kept to DH's own). DH
// reads it only with MCME's mod installed, which loads DH's OpenGL shaders
// from resource packs and gives this one nothing more. The same as the
// override for DH's Blaze3D renderer, in ../blaze.
// Over the fire eye itself one opens up, so the eye shows through; round
// that, the eye's glow lights it.

in vec4 fColor;
in vec3 fRelative;
flat in vec3 fEye;

out vec4 fragColor;

#moj_import <minecraft:mordor_dh_clouds.glsl>

void main()
{
    fragColor = fColor;
    mcmeDhCloud(fragColor);
}
