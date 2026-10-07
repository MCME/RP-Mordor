#version 330

// Vanilla 26.2's sky vertex shader, passing on the direction each point of
// the sky lies in, and where the camera truly is, for the fire eye in sky.fsh.
//
// The sky above is a flat disc, 16 up and 512 out, so it ends just above the
// horizon, and the eye can't be painted below that - where it mostly is, seen
// from up high. So while sky.fsh paints the eye, the disc's rim is pulled far
// down, making it a pyramid round the camera reaching nearly straight down;
// sky.fsh still draws the sky only where the disc was.

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:far_terrain.glsl>
#moj_import <minecraft:fire_eye_config.glsl>
#moj_import <minecraft:fire_eye_sky.glsl>

in vec3 Position;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec3 skyDirection;
out float skyAbove;
flat out vec3 skyOrigin;

void main() {
    vec3 position = Position;
    // the disc above; the one below the horizon is at -16
    skyAbove = Position.y > 0.0 ? 1.0 : 0.0;
    if (fireSkyPulled() && Position.y > 0.0 && length(Position.xz) > 1.0) {
        position = vec3(Position.x * FIRE_SKY_PULL, -500.0, Position.z * FIRE_SKY_PULL);
    }
    gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(position);
    cylindricalVertexDistance = fog_cylindrical_distance(position);
    // around the camera, in the world's directions
    skyDirection = position;
    // where the camera truly is, as fire_eye_main.glsl finds it: the game
    // puts its view bobbing into the projection, moving it off the origin as
    // the player walks - the centre the projection draws towards, which it
    // maps to w = 0
    vec4 eyePoint = inverse(ProjMat * ModelViewMat) * vec4(0.0, 0.0, 1.0, 0.0);
    skyOrigin = abs(eyePoint.w) > 1.0e-6 ? eyePoint.xyz / eyePoint.w : vec3(0.0);
}
