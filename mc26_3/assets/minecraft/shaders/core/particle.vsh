#version 330
// 26.3's copy of assets/minecraft/shaders/core/particle.vsh, translated by ResourcePackScripts' shader_base.py: don't edit it.
#extension GL_ARB_separate_shader_objects : require

// Vanilla 26.2's particle vertex shader. With a distant terrain mod, particles
// past the server's view distance are dropped: they come from chunks that are
// loaded but not drawn - past the render distance, which is a sphere - and,
// drawn, would show through the mod's terrain in front of them, which they
// know nothing of.

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>
#include <minecraft:far_terrain.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;
layout(location = 3) in ivec2 UV2;

uniform sampler2D Sampler2;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec2 texCoord0;
layout(location = 3) out vec4 vertexColor;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    texCoord0 = UV0;
    vertexColor = Color * sample_lightmap(Sampler2, UV2);

    if (farTerrain(FogRenderDistanceStart) && length(Position) > SERVER_VIEW_DISTANCE) {
        gl_Position = vec4(0.0);
    }
}
