#version 330

// Vanilla 26.2's sky vertex shader, passing on the direction each point of
// the sky lies in, for the fire eye in sky.fsh.

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec3 skyDirection;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    // around the camera, in the world's directions
    skyDirection = Position;
}
