// Tar: the tar pit - powder snow - near black and stagnant, its swirls
// slowly changing where they lie, a faint gloss along some of their ridges, a
// wrinkled skin, grit and ash caught in it, and bubbles swelling slowly on
// its top, dull glossy domes that burst into a dark hole, rings spreading out
// after; a dark, dull crust along its banks. Lit as any block. Drawn per pixel over the faces of what shows the tar's textures
// (block/powder_snow to powder_snow_4), fixed in the world; its gloss is the
// same from wherever it is seen, as nothing else in the world reflects.
// Pixelated as a 16px texture is (TAR_PIXEL); its settings are in
// tar_config.glsl. Needs fluid.glsl, which tells its faces from others
// (fluidKind) - see there - and water.glsl, whose shores give its crust: the
// game shades the corners of a block's faces that other blocks crowd, with
// smooth lighting, in vanilla as with Sodium - see there.

#define TAR FLUID_TAR

// How long a bubble takes to swell, burst and settle, in seconds: each
// divides the day's 1200, so bubbles come back as the day's clock starts over.
const float TAR_BUBBLE_TIMES[5] = float[5](8.0, 10.0, 12.0, 15.0, 20.0);

// A bubble at q (blocks), time seconds into the day: in some squares of
// TAR_BUBBLE_SPACING at a time, swelling into a dome lit from the north-west
// for most of its time, then bursting: a dark hole, and rings spreading
// out. What it does to the tar there: x its lightening (or darkening), y
// its gloss.
vec2 tarBubble(vec2 q, float time) {
    vec2 b = q / TAR_BUBBLE_SPACING;
    ivec2 cell = ivec2(floor(b));
    ivec2 id = cell & (int(64.0 / TAR_BUBBLE_SPACING) - 1);
    float period = TAR_BUBBLE_TIMES[int(fluidRand(ivec4(id, 0, 900)) * 4.99)];
    float t = time / period + fluidRand(ivec4(id, 1, 900)) * 5.0;
    int rise = int(floor(t)) % int(1200.0 / period);
    float life = fract(t);
    if (fluidRand(ivec4(id, rise, 901)) > TAR_BUBBLES) return vec2(0.0);
    vec2 at = (vec2(cell) + 0.3 + 0.4 * vec2(fluidRand(ivec4(id, rise, 902)), fluidRand(ivec4(id, rise, 903)))) * TAR_BUBBLE_SPACING;
    vec2 d = q - at;
    float size = TAR_BUBBLE_SIZE * 0.5 * (0.45 + 0.55 * fluidRand(ivec4(id, rise, 904)));
    if (life < 0.7) {
        // swelling, slowly, then faster
        float r = size * pow(life / 0.7, 0.6);
        float dome = 1.0 - step(r, length(d));
        float rim = (1.0 - step(r + TAR_PIXEL, length(d))) - dome;
        // a highlight to the north-west of its top, and a darker rim round it
        float shine = 1.0 - step(r * 0.35, length(d + vec2(0.35, 0.35) * r));
        return vec2(dome * 0.2 - rim * 0.3, dome * shine * 0.45);
    }
    // bursting: the hole, then two rings spreading out and fading
    float burst = (life - 0.7) / 0.3;
    float hole = (1.0 - step(size * (1.0 - burst), length(d))) * (1.0 - burst);
    float ring1 = 1.0 - step(TAR_PIXEL, abs(length(d) - size * (1.0 + 2.5 * burst)));
    float ring2 = 1.0 - step(TAR_PIXEL, abs(length(d) - size * (0.6 + 1.8 * burst)));
    return vec2(-0.4 * hole, (ring1 * 0.3 + ring2 * 0.18) * (1.0 - burst));
}

// The tar's colour at f, time seconds into the day; shore from water.glsl's
// waterShore.
vec3 tarColor(FluidFrame f, float time, WaterShore shore) {
    vec3 n = fluidNormal(f);
    bool top = abs(n.y) > 0.6;
    vec3 axisU = top ? vec3(1.0, 0.0, 0.0) : abs(n.x) > abs(n.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 axisV = top ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);

    // pixelated: the face is cut into squares of TAR_PIXEL blocks
    vec2 s = vec2(dot(f.world, axisU), dot(f.world, axisV));
    vec2 here = (floor(s / TAR_PIXEL) + 0.5) * TAR_PIXEL;
    float pixel = max(max(length(f.dx), length(f.dy)), TAR_PIXEL);

    // ---- slow, heavy swirls, changing where they lie: the noise's third
    // axis is time, a whole number of its periods a day
    float change = time * (64.0 * float(TAR_CHANGE) / 1200.0);
    vec3 q3 = vec3(here, change);
    vec2 q = here + (vec2(fluidNoise3(q3, 0.25, 910), fluidNoise3(q3 + 31.0, 0.25, 911)) - 0.5) * 3.0;
    q += fluidWarp(q, vec2(1.0), pixel, 912) * 0.4;
    float swirl = fluidNoise3(vec3(q, change + 7.0), 0.5, 914) * 0.7 + fluidNoise(q + 9.0, vec2(2.0), pixel, 915) * 0.3;
    float ridge = 1.0 - abs(2.0 * swirl - 1.0);
    vec3 color = TAR_COLOR * (1.0 + (swirl - 0.5) * 2.0 * TAR_SWIRL);
    // gloss: thin, along the ridges of some of its swirls only, and a soft
    // sheen on its swells
    float glossy = smoothstep(0.5, 0.8, fluidNoise(here, vec2(0.25), pixel, 916));
    float gloss = smoothstep(0.95, 0.995, ridge) * glossy * TAR_GLOSS + smoothstep(0.65, 0.95, swirl) * 0.03;

    // ---- detail: a faint mottling, a fine wrinkled skin, a few lumps, and
    // grit and ash caught in it
    color *= 0.92 + 0.16 * fluidNoise(here, vec2(4.0), pixel, 920);
    float wrinkles = 1.0 - abs(2.0 * fluidNoise(here + fluidWarp(here, vec2(2.0), pixel, 921) * 0.4, vec2(8.0, 4.0), pixel, 923) - 1.0);
    color *= 1.0 - smoothstep(0.85, 0.97, wrinkles) * TAR_SKIN;
    float lumps = smoothstep(0.7, 0.85, fluidNoise(here, vec2(2.0), pixel, 925));
    color *= 1.0 + lumps * 0.12;
    gloss = max(gloss, lumps * smoothstep(0.85, 0.9, fluidNoise(here + vec2(0.06, 0.06), vec2(2.0), pixel, 925)) * 0.08);
    // (in patches, not everywhere)
    float grit = step(1.0 - TAR_GRIT, fluidRand(ivec4(ivec2(floor(here / TAR_PIXEL)) & 1023, 0, 930)))
               * smoothstep(0.55, 0.7, fluidNoise(here, vec2(0.5), pixel, 931))
               * (1.0 - smoothstep(1.5, 3.0, pixel / TAR_PIXEL));
    color = mix(color, TAR_GRIT_COLOR * (0.7 + 0.6 * fluidRand(ivec4(ivec2(floor(here / TAR_PIXEL)) & 1023, 1, 930))), grit * 0.8);

    // ---- bubbles, on its top
    if (top) {
        vec2 bubble = tarBubble(here, time) * (1.0 - smoothstep(1.5, 3.0, pixel / TAR_PIXEL));
        color *= 1.0 + bubble.x;
        gloss = max(gloss, bubble.y * 0.8);
    }

    // ---- a crust along its banks: darkest at them, its edge ragged, and
    // dull - no gloss, no bubbles showing through
    float away = waterAway(shore, f, axisU * (here.x - s.x) + axisV * (here.y - s.y));
    float ragged = fluidNoise(here, vec2(4.0), pixel, 940) * 0.6 + fluidNoise(here, vec2(16.0), pixel, 941) * 0.4;
    float reach = TAR_EDGE * (0.55 + 0.9 * ragged);
    float crust = (1.0 - smoothstep(reach - TAR_PIXEL, reach, away)) * (0.65 + 0.35 * (1.0 - clamp(away / reach, 0.0, 1.0)));
    color = mix(color, TAR_EDGE_COLOR * (0.8 + 0.5 * fluidNoise(here, vec2(8.0), pixel, 942)), crust);
    gloss *= 1.0 - crust;
    return mix(color, TAR_GLOSS_COLOR, gloss);
}
