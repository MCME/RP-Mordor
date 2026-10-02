// The game's time, for a shader that isn't given it but samples the lightmap:
// Distant Horizons' terrain (distanthorizons:terrain/blaze), so the eye it
// paints moves as the rest of it does. core/lightmap.fsh hides the tick of the
// day in the lowest bit of the colours of a few texels - a 1/255 step no one
// sees - and it is rebuilt every tick.

#define FIRE_CLOCK_ROW 15     // the texels' row: full sky light
#define FIRE_CLOCK_TEXELS 5   // 3 bits each: 15, enough for a day's 24000 ticks

// color, the lightmap's at texel, with its share of the tick of gameTime (the
// day's fraction, Globals' GameTime) in its lowest bits
vec3 fireClockEncode(vec3 color, ivec2 texel, float gameTime) {
    if (texel.y != FIRE_CLOCK_ROW || texel.x >= FIRE_CLOCK_TEXELS) return color;
    uint bits = (uint(gameTime * 24000.0 + 0.5) % 24000u) >> uint(texel.x * 3);
    uvec3 c = uvec3(clamp(color, 0.0, 1.0) * 255.0 + 0.5);
    c = (c & ~1u) | uvec3(bits & 1u, (bits >> 1) & 1u, (bits >> 2) & 1u);
    return vec3(c) / 255.0;
}

// the time, in seconds into the day, as fire_eye.glsl's fireTime
float fireClockSeconds(sampler2D lightmap) {
    uint ticks = 0u;
    for (int i = 0; i < FIRE_CLOCK_TEXELS; i++) {
        uvec3 c = uvec3(texelFetch(lightmap, ivec2(i, FIRE_CLOCK_ROW), 0).rgb * 255.0 + 0.5);
        ticks |= ((c.r & 1u) | ((c.g & 1u) << 1) | ((c.b & 1u) << 2)) << uint(i * 3);
    }
    return float(ticks) / 20.0;
}
