// Ice: packed and blue ice, seen into - through their faces, in layers going
// a block deep as the lava's and water's do: cracks frozen into it at every
// depth, small trapped bubbles and clouding, bluer the deeper; faint
// scratches on its surface, a sheen at a glance, and frost where it meets
// other blocks, glinting now and then. Drawn per pixel over the faces of
// what shows block/packed_ice or block/blue_ice, fixed in the world.
// Pixelated as a 16px texture is (ICE_PIXEL); its settings are in
// ice_config.glsl. Needs fluid.glsl, which tells its faces from others
// (fluidKind), and water.glsl, whose shores give its frost: the game shades
// the corners of a block's faces that other blocks crowd, with smooth
// lighting, in vanilla as with Sodium - see there.

#define ICE_PACKED FLUID_PACKED_ICE
#define ICE_BLUE FLUID_BLUE_ICE

// Its cracks at a layer: where it is between the cells of a warped pattern,
// as thin bright lines - none in some places. q in blocks; salt the layer's.
float iceFracture(vec2 q, float pixel, int salt) {
    vec2 p = (q + fluidWarp(q, vec2(0.5), pixel, salt + 300) * 1.2 * ICE_FRACTURE_SIZE
              + fluidWarp(q, vec2(4.0), pixel, salt + 310) * 0.1) / ICE_FRACTURE_SIZE;
    ivec2 cell = ivec2(floor(p));
    int mask = int(64.0 / ICE_FRACTURE_SIZE) - 1;
    float near = 1.0e9, second = 1.0e9;
    for (int k = 0; k < 9; k++) {
        ivec2 o = cell + ivec2(k % 3 - 1, k / 3 - 1);
        ivec2 id = o & mask;
        float d = length(p - vec2(o) - vec2(fluidRand(ivec4(id, salt, 320)), fluidRand(ivec4(id, salt, 321))));
        second = d < near ? near : min(second, d);
        near = min(near, d);
    }
    float inside = (second - near) * 0.5 * ICE_FRACTURE_SIZE;
    float line = 1.0 - smoothstep(0.5 * max(ICE_PIXEL, pixel), max(ICE_PIXEL, pixel), inside);
    return line * smoothstep(0.35, 0.6, fluidNoise(q, vec2(1.0), pixel, salt + 330));
}

// A small bubble at q, frozen in: one in some cells of a quarter block.
float iceBubble(vec2 q, float pixel, int salt) {
    vec2 b = q * 4.0;
    ivec2 cell = ivec2(floor(b));
    ivec2 id = cell & 255;
    if (fluidRand(ivec4(id, salt, 340)) > ICE_BUBBLES) return 0.0;
    vec2 at = vec2(cell) + 0.25 + 0.5 * vec2(fluidRand(ivec4(id, salt, 341)), fluidRand(ivec4(id, salt, 342)));
    float r = (0.06 + 0.06 * fluidRand(ivec4(id, salt, 343))) * 4.0;
    float d = length(b - at);
    float seen = smoothstep(0.5, 1.5, 0.25 * r / pixel);
    return (1.0 - smoothstep(r * 0.6, r, d)) * seen;
}

// The ice's colour at f, a face of kind, time seconds into the day, and how
// much of it is frost (alpha), which the light of what crowds it doesn't
// dim; shore from water.glsl's waterShore, sky the sky's colour.
vec4 iceColor(int kind, FluidFrame f, float time, WaterShore shore, vec3 sky) {
    vec3 n = fluidNormal(f);
    bool top = abs(n.y) > 0.6;
    vec3 axisU = top ? vec3(1.0, 0.0, 0.0) : abs(n.x) > abs(n.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 axisV = top ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);

    // pixelated: the face is cut into squares of ICE_PIXEL blocks, each
    // traced once, through its middle
    vec2 s = vec2(dot(f.world, axisU), dot(f.world, axisV));
    vec2 snap = (floor(s / ICE_PIXEL) + 0.5) * ICE_PIXEL - s;
    vec3 shift = axisU * snap.x + axisV * snap.y;
    vec3 world = f.world + shift;
    vec3 ray = normalize(f.pos + shift);
    float pixel = max(max(length(f.dx), length(f.dy)), ICE_PIXEL);

    bool isPacked = kind == ICE_PACKED;
    vec3 surface = isPacked ? ICE_PACKED_SURFACE : ICE_BLUE_SURFACE;
    vec3 deep = isPacked ? ICE_PACKED_DEEP : ICE_BLUE_DEEP;
    float cloudiness = isPacked ? ICE_PACKED_CLOUD : ICE_BLUE_CLOUD;

    // ---- inside: layer after layer going in, the light from each dimmed by
    // what lies in front of it - clouding, and the ice itself
    float into = max(-dot(ray, n), 0.25);
    vec3 color = vec3(0.0);
    float through = 1.0;
    for (int i = 0; i < ICE_LAYERS; i++) {
        float depth = (float(i) + 0.5) / float(ICE_LAYERS) * ICE_DEPTH;
        vec3 at = world + ray * (depth / into);
        // each layer sees the ice along its own axes, turned, so the
        // patterns don't line up
        vec2 q = FLUID_TURN[i] * vec2(dot(at, axisU), dot(at, axisV));
        float cloud = fluidNoise(q, vec2(1.0), pixel, i + 350) * 0.6 + fluidNoise(q + 5.0, vec2(4.0), pixel, i + 360) * 0.4;
        cloud = smoothstep(0.35, 0.8, cloud) * cloudiness;
        vec3 layer = mix(surface, deep, (float(i) + 0.5) / float(ICE_LAYERS));
        float crack = iceFracture(q, pixel, i);
        float bubble = iceBubble(q, pixel, i);
        vec3 seen = layer * (0.75 + 0.5 * cloud) + vec3(0.95, 0.98, 1.0) * (crack * ICE_FRACTURES + bubble * 0.5);
        float share = 1.0 / float(ICE_LAYERS) + cloud * 0.4;
        color += seen * share * through;
        through *= 1.0 - min(share, 0.9);
    }
    color += deep * through;

    // ---- its surface: faint scratches, and the sky's colour at a glance
    vec2 here = vec2(dot(world, axisU), dot(world, axisV));
    float scratches = 1.0 - abs(2.0 * fluidNoise(here + fluidWarp(here, vec2(2.0), pixel, 370) * 0.3, vec2(8.0, 1.0), pixel, 372) - 1.0);
    color += vec3(0.08) * smoothstep(0.9, 0.98, scratches);
    float glance = pow(1.0 - clamp(-dot(ray, n), 0.0, 1.0), 3.0);
    color = mix(color, sky, glance * ICE_SHEEN);

    // ---- frost where other blocks crowd it, its edge ragged, a few of its
    // pixels glinting in turn
    float away = waterAway(shore, f, shift);
    float ragged = fluidNoise(here, vec2(4.0), pixel, 380) * 0.6 + fluidNoise(here, vec2(16.0), pixel, 381) * 0.4;
    float frost = 1.0 - smoothstep(ICE_FROST * (0.5 + ragged) - ICE_PIXEL, ICE_FROST * (0.5 + ragged), away);
    float glint = fluidRand(ivec4(ivec2(floor(here / ICE_PIXEL)) & 1023, 0, 390));
    // (each glints 60 times a day, so all comes round as the day's clock does)
    float twinkle = smoothstep(0.9, 1.0, sin(time * (6.2831853 * 60.0 / 1200.0) + glint * 6.2831853 * 7.0));
    color = mix(color, ICE_FROST_COLOR * (0.85 + 0.25 * ragged), frost);
    color += vec3(0.5) * frost * step(1.0 - ICE_SPARKLE, glint) * twinkle;
    return vec4(color, frost);
}
