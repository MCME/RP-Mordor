#version 330

// Vanilla 26.2's particle vertex shader. With a distant terrain mod, particles
// past the server's view distance are dropped: they come from chunks that are
// loaded but not drawn - past the render distance, which is a sphere - and,
// drawn, would show through the mod's terrain in front of them, which they
// know nothing of.

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#moj_import <minecraft:far_terrain.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;

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
