#version 330
// 26.3's copy of assets/minecraft/shaders/core/sky.vsh, translated by ResourcePackScripts' shader_base.py: don't edit it.
#extension GL_ARB_separate_shader_objects : require

// Vanilla 26.2's sky vertex shader, passing on the direction each point of
// the sky lies in, and where the camera truly is, for the fire eye in sky.fsh.
//
// The sky above is a flat disc, 16 up and 512 out, so it ends just above the
// horizon, and the eye can't be painted below that - where it mostly is, seen
// from up high. So while sky.fsh paints the eye, the disc's rim is pulled far
// down, making it a pyramid round the camera reaching nearly straight down;
// sky.fsh still draws the sky only where the disc was.

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:far_terrain.glsl>
#include <minecraft:fire_eye_config.glsl>
#include <minecraft:fire_eye_sky.glsl>

layout(location = 0) in vec3 Position;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec3 skyDirection;
layout(location = 3) out float skyAbove;
layout(location = 4) flat out vec3 skyOrigin;

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
