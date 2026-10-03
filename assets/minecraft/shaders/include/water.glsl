// Water: the game's water, its colour the biome's as ever, with faint
// ripples drifting over it in layers - deeper ones shifting with the view, as
// the lava's do - streaks where it flows, and foam, blended in: on flowing
// water and falls, now and then in a small wave crossing still water, and,
// with Sodium, along its shores. No reflections, as nothing else in the
// world has them. Drawn per pixel over water's faces -
// the fluid's, and the pack's models textured with it - fixed in the world.
// Pixelated as a 16px texture is (WATER_PIXEL); its settings are in
// water_config.glsl. Needs fluid.glsl, which tells its faces from others
// (fluidKind) - see there.
//
// Shores: Sodium lights water by the blocks round it (smooth lighting),
// darkening the corners of its faces that touch them. The vertex shader
// passes each corner's brightness on in a slot of its own, and a 1 in that
// slot alongside (water_corner.glsl's waterCorner), so the fragment knows its
// triangle's corners, and where it is between them. A corner darker than the
// brightest is on a shore, and so is an edge between two such corners: the
// foam is drawn by how far the fragment is from those - by which corners are
// darkened, not how much, nor the biome's colour or the light, which are the
// same at every corner. Vanilla doesn't darken water so: without Sodium there
// is no shore foam.

#define WATER_STILL FLUID_WATER_STILL
#define WATER_FLOWING FLUID_WATER_FLOWING

// What the water looks like at a fragment, for its shader to draw with the
// colour and light it has always had.
struct WaterLook {
    float shade;    // its brightness, over its own lit colour: about 1
    float foam;     // how much of it is foam, 0 to 1
    float alpha;
};

// Where on its face a fragment is, and which corners of its triangle are on
// a shore, for waterLook: from what water_corner.glsl's waterCorner wrote,
// interpolated. Taken before any branching, as it needs derivatives.
struct WaterShore {
    vec2 at;          // where on its face: 0 to 1 along each side
    vec2 dx, dy;      // at's change to the next pixel across and up
    vec4 shore;       // per corner: 1 on a shore, 0 not, -1 not this triangle's
    float open;       // the brightest corner's brightness: the face's own, unoccluded
};

// The corners of a face, in the order its vertices come in.
const vec2 WATER_CORNERS[4] = vec2[4](vec2(0.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0), vec2(1.0, 0.0));

WaterShore waterShore(vec4 lights, vec4 weights) {
    WaterShore s;
    float brightest = 0.0;
    vec4 corner = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        corner[k] = weights[k] > 1.0e-3 ? lights[k] / weights[k] : 0.0;
        brightest = max(brightest, corner[k]);
    }
    s.at = vec2(0.0);
    for (int k = 0; k < 4; k++) {
        s.at += weights[k] * WATER_CORNERS[k];
        // darker than the brightest by more than the biome's colour or the
        // light would make it
        s.shore[k] = weights[k] > 1.0e-3 ? (corner[k] < brightest * 0.92 ? 1.0 : 0.0) : -1.0;
    }
    s.open = brightest;
    s.dx = dFdx(s.at);
    s.dy = dFdy(s.at);
    return s;
}

// How far point p is from the segment a to b.
float waterToSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    return length(p - a - ab * clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0));
}

// How far, along its face, the fragment at s - at its pixel's middle, shift
// away in the world - is from its shores: in sides of the face, about blocks.
float waterAway(WaterShore s, FluidFrame f, vec3 shift) {
    // at's gradients along the face, each dotted with the shift giving its
    // change over it, as fluidFlow() finds the flow's
    vec3 across = cross(f.dx, f.dy);
    float aa = dot(across, across);
    vec2 at = s.at;
    if (aa > 0.0) {
        vec3 gu = (s.dx.x * cross(f.dy, across) + s.dy.x * cross(across, f.dx)) / aa;
        vec3 gv = (s.dx.y * cross(f.dy, across) + s.dy.y * cross(across, f.dx)) / aa;
        at += vec2(dot(gu, shift), dot(gv, shift));
    }
    float away = 1.0e9;
    for (int k = 0; k < 4; k++) {
        if (s.shore[k] > 0.5) {
            away = min(away, length(at - WATER_CORNERS[k]));
            if (s.shore[(k + 1) & 3] > 0.5) away = min(away, waterToSegment(at, WATER_CORNERS[k], WATER_CORNERS[(k + 1) & 3]));
        }
    }
    return away;
}

// How long a wave takes to come round again, in seconds: each divides the
// day's 1200, so waves come back as the day's clock starts over.
const float WATER_WAVE_TIMES[4] = float[4](20.0, 24.0, 30.0, 40.0);

// A small wave on still water at here (blocks): in some squares of
// WATER_WAVE_SPACING now and then, a short crest, bowed forward, crossing
// WATER_WAVE_TRAVEL blocks one of eight ways as it rises and dies away.
float waterWave(vec2 here, float time) {
    vec2 g = here / WATER_WAVE_SPACING;
    ivec2 cell = ivec2(floor(g));
    int mask = int(64.0 / WATER_WAVE_SPACING) - 1;
    float wave = 0.0;
    for (int k = 0; k < 9; k++) {
        ivec2 o = cell + ivec2(k % 3 - 1, k / 3 - 1);
        ivec2 id = o & mask;
        float period = WATER_WAVE_TIMES[int(fluidRand(ivec4(id, 0, 700)) * 3.99)];
        float t = time / period + fluidRand(ivec4(id, 1, 700)) * 3.0;
        int rise = int(floor(t)) % int(1200.0 / period);
        float life = fract(t) / 0.4;
        if (life >= 1.0 || fluidRand(ivec4(id, rise, 701)) > WATER_WAVES) continue;
        vec2 start = (vec2(o) + vec2(fluidRand(ivec4(id, rise, 702)), fluidRand(ivec4(id, rise, 703)))) * WATER_WAVE_SPACING;
        float a = floor(fluidRand(ivec4(id, rise, 704)) * 8.0) * 0.7853982;
        vec2 dir = vec2(cos(a), sin(a));
        vec2 d = here - start - dir * life * WATER_WAVE_TRAVEL;
        float across = dot(d, vec2(-dir.y, dir.x));
        float ahead = dot(d, dir) + 0.25 * across * across;
        // its crest two pixels deep, and a wake fading out behind it
        float crest = (1.0 - smoothstep(WATER_PIXEL, WATER_PIXEL * 2.0, abs(ahead)))
                    + (ahead < 0.0 ? exp(ahead * 6.0) * 0.35 : 0.0);
        crest *= 1.0 - smoothstep(0.7, 1.3, abs(across));
        wave = max(wave, min(crest, 1.0) * sin(life * 3.1415927));
    }
    return wave;
}

// The water's look at f, a face of kind, time seconds into the day; shore
// from waterShore.
WaterLook waterLook(int kind, FluidFrame f, float time, WaterShore shore) {
    vec3 n = fluidNormal(f);
    bool top = abs(n.y) > 0.6;
    // the face's own axes: x and z on top (and on flowing water's slopes),
    // along it and up on its sides - always the world's own axes
    vec3 axisU = top ? vec3(1.0, 0.0, 0.0) : abs(n.x) > abs(n.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 axisV = top ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);

    // pixelated: the face is cut into squares of WATER_PIXEL blocks, each
    // traced once, through its middle
    vec2 s = vec2(dot(f.world, axisU), dot(f.world, axisV));
    vec2 snap = (floor(s / WATER_PIXEL) + 0.5) * WATER_PIXEL - s;
    vec3 shift = axisU * snap.x + axisV * snap.y;
    vec3 world = f.world + shift;
    vec3 ray = normalize(f.pos + shift);
    float pixel = max(max(length(f.dx), length(f.dy)), WATER_PIXEL);

    // how it moves: flowing water along its texture's flow, faster on top
    // than below; still water drifting, each layer its own way
    vec3 v = fluidFlow(f);
    vec2 flow = vec2(dot(v, axisU), dot(v, axisV));
    bool flowing = kind == WATER_FLOWING && dot(flow, flow) > 0.0;
    ivec2 way = flowing ? fluidWay(flow) : ivec2(0);
    int steps = top ? WATER_FLOW_STEPS : WATER_FALL_STEPS;
    mat2 along = fluidAlong(way);
    vec2 stretch = flowing ? vec2(top ? 0.5 : 0.25, 1.0) : vec2(1.0);
    vec2 here = vec2(dot(world, axisU), dot(world, axisV));

    // ---- ripples: layers of soft swells, deeper ones seen further along
    // the view ray, each drifting and turned its own way; light caught on
    // the crests of the top one
    float into = max(-dot(ray, n), 0.3);
    float ripple = 0.0;
    float weight = 0.0;
    float crest = 0.0;
    for (int i = 0; i < WATER_LAYERS; i++) {
        vec3 at = world + ray * (float(i) * WATER_LAYER_DEPTH / into);
        vec2 q = vec2(dot(at, axisU), dot(at, axisV));
        ivec2 drift = flowing ? way * ((steps * (5 - i) + 2) / 5) + ivec2(-way.y, way.x) * ((i & 1) == 1 ? 1 : -1)
                              : FLUID_STIR[i] * WATER_STIR;
        q -= vec2(drift) * FLUID_STEP * time;
        q = flowing ? along * q : FLUID_TURN[i] * q;
        vec2 cells = FLUID_CELLS[i] * stretch;
        q += fluidWarp(q, cells * 0.5, pixel, i + 120) * 0.8 / cells;
        float a = fluidNoise(q, cells, pixel, i + 100) * 0.65 + fluidNoise(q + 13.0, cells * 2.0, pixel, i + 110) * 0.35;
        float w = 1.0 / (1.0 + 0.6 * float(i));
        ripple += a * w;
        weight += w;
        if (i == 0) crest = smoothstep(0.86, 0.97, 1.0 - abs(2.0 * a - 1.0));
    }
    ripple = ripple / weight - 0.5;

    // ---- streaks along flowing water, top and falls: fine lines drawn out
    // along it, running with it
    vec2 c = along * (here - vec2(flowing ? way * steps : FLUID_STIR[0] * WATER_STIR) * FLUID_STEP * time);
    float streak = 0.0;
    if (flowing) {
        float lines = 1.0 - abs(2.0 * fluidNoise(c + fluidWarp(c, vec2(0.5, 1.0), pixel, 136) * 0.5, vec2(0.25, 4.0), pixel, 135) - 1.0);
        streak = smoothstep(0.75, 0.95, lines);
    }

    WaterLook look;
    look.shade = 1.0 + ripple * 2.0 * WATER_RIPPLE + crest * WATER_CREST + streak * WATER_STREAK;

    // ---- foam: where it flows - more where its top runs steeper, most on
    // falls - now and then a small wave crossing still water, and, with
    // Sodium, a lapping band along its shores; softened and broken up
    float foam = 0.0;
    if (flowing) {
        float amount = top ? WATER_FOAM * (0.4 + 0.6 * (1.0 - smoothstep(0.75, 0.98, abs(n.y)))) : WATER_FALL_FOAM;
        float streaks = fluidNoise(c, vec2(1.0, 4.0) * stretch, pixel, 130) * 0.6 + fluidNoise(c + 7.0, vec2(2.0, 8.0) * stretch, pixel, 131) * 0.4;
        foam = smoothstep(1.0 - amount * 0.75, 1.0 - amount * 0.75 + 0.12, streaks + (fluidNoise(c, vec2(8.0, 16.0), pixel, 134) - 0.5) * 0.12);
    } else if (top) {
        foam = waterWave(here, time) * 1.6;
    }
    float away = waterAway(shore, f, shift);
    // a band along the shore, its edge lapping in and out, and a thin line
    // of foam beyond it, washing in and out on its own swell
    float lap = fluidNoise(c + vec2(FLUID_STIR[2]) * FLUID_STEP * time * 4.0, vec2(2.0), pixel, 132);
    float band = (0.2 + (lap - 0.5) * 0.12) * WATER_SHORE_FOAM;
    // (172 swells a day, so they too are where they were when the day's
    // clock starts over)
    float wash = band + (0.1 + 0.04 * sin(time * (6.2831853 * 172.0 / 1200.0) + lap * 6.0)) * WATER_SHORE_FOAM;
    foam = max(foam, (1.0 - smoothstep(band - WATER_PIXEL, band, away)) * 0.8);
    foam = max(foam, (step(wash, away) - step(wash + 0.06, away)) * step(0.45, lap) * 0.6);
    float bubbles = fluidNoise(c, vec2(16.0), pixel, 133);
    look.foam = foam * smoothstep(0.2, 0.6, bubbles + foam * 0.4) * WATER_FOAM_OPACITY;
    look.alpha = mix(WATER_ALPHA, 0.9, look.foam);
    return look;
}
