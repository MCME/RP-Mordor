// What RP-Mordor's own fluids share, beyond the shader base's fluid.glsl
// (ResourcePackScripts/shaderBase), which this needs: their kinds - the base
// keeps 5 to 7 for a pack's own - and a noise in three dimensions.
//
// Their textures are signed with ResourcePackScripts'
// lavaSignature/sign_fluids.py, again after every edit of them.

#define FLUID_TAR 6                  // (5 and 7: the fog block and the spray, on their own branch)

// Smooth value noise in three dimensions, on a lattice of cells per block,
// repeating every 64 blocks along each axis, as the world's coordinates here
// do - or 64 of whatever units else, such as time in steps.
float fluidNoise3(vec3 p, float cells, int salt) {
    vec3 g = p * cells;
    ivec3 c = ivec3(floor(g));
    vec3 f = fract(g);
    f = f * f * (3.0 - 2.0 * f);
    int period = int(64.0 * cells + 0.5);
    ivec3 c0 = c - period * ivec3(floor(vec3(c) / float(period)));
    float n = 0.0;
    for (int k = 0; k < 8; k++) {
        ivec3 o = ivec3(k & 1, (k >> 1) & 1, (k >> 2) & 1);
        ivec3 at = c0 + o - period * ivec3(greaterThanEqual(c0 + o, ivec3(period)));
        vec3 w = mix(1.0 - f, f, vec3(o));
        n += w.x * w.y * w.z * fluidRand(ivec4(at, salt));
    }
    return n;
}
