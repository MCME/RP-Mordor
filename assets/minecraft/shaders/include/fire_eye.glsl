// The fire eye: a burning ball some FIRE_RADIUS blocks round its block - shells
// of flame one inside the other, turning (after Shadertoy wdVXWR), a dark
// crust drifting over them - with a slit pupil on it, ringed by a white-hot
// iris that fine rays stream out from. It looks away, glance after glance, and
// now and then turns on whoever sees it. Round it, a fiery almond fixed in the
// world, flames streaming out from behind the ball, and a wide glow. All of it
// is ray traced per pixel on camera-facing quads that its vertex part
// (fire_eye_main.glsl) makes of its model's faces; fireColor() is its colour
// there.
//
// Shared by vanilla's terrain.fsh, Sodium's block_layer_opaque.fsh and the
// sky (core/sky.fsh). Pos is the fragment's position relative to the camera; fireLayer,
// fireCentre and fireTime are set by whoever imports this.
//
// What costs: the ball and the almond's flames are noise, several layers of
// it, so only the pixels that show them work them out - the glow's take a few
// sums - and the finer layers are left out where the eye is small on screen.
//
// Shader packs can't draw the eye's wide glow on quads: theirs cut off the fog
// and clouds behind anything translucent. They define FIRE_NO_GLOW, so that
// fireColor() is only the eye, and add fireGlowLight() over their finished
// scene instead. FIRE_ONE_LAYER draws all of it on one quad.

uint fireHash(ivec4 p) {
    uint h = uint(p.x) * 73856093u ^ uint(p.y) * 19349663u ^ uint(p.z) * 83492791u ^ uint(p.w) * 2654435761u;
    h ^= h >> 13;
    h *= 0x5bd1e995u;
    h ^= h >> 15;
    return h;
}

float fireRand(ivec4 p) {
    return float(fireHash(p) & 0xFFFFu) / 65535.0;
}

// Value noise on the integer lattice, smoothly interpolated.
float fireValueNoise(vec3 p, int salt) {
    ivec3 i = ivec3(floor(p));
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n = 0.0;
    for (int k = 0; k < 8; k++) {
        ivec3 o = ivec3(k & 1, (k >> 1) & 1, (k >> 2) & 1);
        vec3 w = mix(1.0 - f, f, vec3(o));
        n += w.x * w.y * w.z * fireRand(ivec4(i + o, salt));
    }
    return n;
}

// One layer of it whose cells are 1/cells radii across, seen at pixel radii
// to a pixel: where its cells shrink under a pixel it fades to its average,
// as a mipmapped texture does - and isn't worked out at all once gone.
float fireOctave(vec3 p, int salt, float cells, float pixel) {
    float seen = 1.0 - smoothstep(0.5, 1.0, cells * pixel);
    return seen > 0.0 ? mix(0.5, fireValueNoise(p, salt), seen) : 0.5;
}

// Heat as colour: deep orange, through gold, to white only where hottest.
vec3 fireShade(float x) {
    return vec3(1.0, 0.35, 0.04) * x
         + vec3(1.0, 0.58, 0.08) * clamp(x - 0.38, 0.0, 1.0)
         + vec3(0.9, 0.85, 0.72) * clamp(x - 0.82, 0.0, 1.0);
}

mat3 fireRotate(float a, vec3 v) {
    float c = cos(a);
    vec3 ci = (1.0 - c) * v;
    vec3 s = sin(a) * v;
    return mat3(ci.x * v.x + c, ci.x * v.y + s.z, ci.x * v.z - s.y,
                ci.y * v.x - s.z, ci.y * v.y + c, ci.y * v.z + s.x,
                ci.z * v.x + s.y, ci.z * v.y - s.x, ci.z * v.z + c);
}

// In place of the original's noise texture: white noise on a lattice of
// FIRE_CELLS per unit, linearly filtered like a texture. Where its cells get
// smaller than a pixel (`footprint` cells to one) it fades to its average, as
// a mipmapped texture does.
float fireNoise(vec2 uv, float footprint, int layer) {
    vec2 g = uv * FIRE_CELLS;
    ivec2 c = ivec2(floor(g));
    vec2 f = fract(g);
    float n = mix(mix(fireRand(ivec4(c, layer, 190)), fireRand(ivec4(c + ivec2(1, 0), layer, 190)), f.x),
                  mix(fireRand(ivec4(c + ivec2(0, 1), layer, 190)), fireRand(ivec4(c + ivec2(1, 1), layer, 190)), f.x), f.y);
    return mix(0.5, n, 1.0 / max(footprint, 1.0));
}

// How far the eye's block hands over to what draws it from afar, at distance
// blocks from the camera: 0 well inside FIRE_HANDOVER, 1 at it - over its last
// chunk. (Shader packs hand over to their own far eye with it.)
float fireHandover(float distance) {
    return smoothstep(FIRE_HANDOVER - 16.0, FIRE_HANDOVER, distance);
}

// How bright each shell's and each of the iris's streams' flames are on
// average, over the noise they're cut from: what they fade to where they're
// finer than a pixel, so the ball keeps its glow from afar
const float FIRE_SHELL_MEAN[9] = float[9](0.028, 0.131, 0.263, 0.36, 0.396, 0.4, 0.4, 0.4, 0.4);
const float FIRE_STREAM_MEAN[4] = float[4](0.15, 0.21, 0.267, 0.324);

// ---------------------------------------------------------------- its gaze

// The glance target i: where the eye looks, in its view's frame - x right, y
// up, both in tangents of the angle - and whether at the viewer (1) or away.
// A glance at the viewer is chosen now and then and held FIRE_LOCK_HOLD
// glances; the others look off to a side and down - all it watches lies
// below it - never more than a little above level.
vec3 fireGlance(int i) {
    bool locked = false;
    for (int k = 0; k < int(FIRE_LOCK_HOLD); k++) locked = locked || fireRand(ivec4(i - k, 3, 0, 270)) < FIRE_LOCK_CHANCE;
    if (locked) return vec3(0.0, 0.0, 1.0);
    float side = (fireRand(ivec4(i, 0, 0, 270)) * 2.0 - 1.0) * FIRE_LOOK;
    float down = mix(-FIRE_LOOK_DOWN, FIRE_LOOK_DOWN * 0.15, fireRand(ivec4(i, 1, 0, 270)));
    // never so near the viewer that it reads as looking at them
    vec2 look = vec2(side, down);
    look *= max(1.0, 0.45 * FIRE_LOOK / max(length(look), 1.0e-3));
    return vec3(look, 0.0);
}

// Where it looks at time seconds: the direction, in its view's frame (z
// towards the viewer), and in lock how fully at the viewer, 0 to 1. It darts
// from glance to glance, and snaps round to the viewer faster.
vec3 fireGaze(float time, out float lock) {
    float g = time / FIRE_LOOK_HOLD;
    int i = int(floor(g));
    float into = fract(g) * FIRE_LOOK_HOLD;
    vec3 from = fireGlance(i - 1);
    vec3 to = fireGlance(i);
    float turn = smoothstep(0.0, to.z > 0.5 ? FIRE_LOCK_SNAP : FIRE_LOOK_DART, into);
    vec3 look = mix(from, to, turn);
    lock = look.z;
    return normalize(vec3(look.xy, 1.0));
}

// ---------------------------------------------------------------- its glow

// The glow round the ball, unpixelated: one glow, orange by the ball,
// reddening and easing away to nothing by FIRE_GLOW radii, and a second,
// larger, fainter one over FIRE_HALO radii. passSmooth is how close the view
// ray passes the eye's centre, in radii.
vec3 fireBallGlow(float passSmooth) {
    vec3 glowShade = mix(fireShade(0.9), vec3(1.0, 0.55, 0.3), smoothstep(1.0, 2.5, passSmooth));
    return FIRE_GLOW_STRENGTH * glowShade * exp(-max(passSmooth - 0.9, 0.0) * FIRE_GLOW_FALLOFF)
         * (1.0 - smoothstep(FIRE_GLOW * 0.25, FIRE_GLOW, passSmooth));
}

// The second glow thins from the start, with no flat middle to end in a rim,
// and eases into nothing; and it is a light, warm orange - in the resource
// pack it is blended over the sky, not added to it, and a deep red would
// darken a pale sky into a disc.
vec3 fireHalo(float passSmooth) {
    float h = min(passSmooth / FIRE_HALO, 1.0);
    return FIRE_HALO_STRENGTH * vec3(1.0, 0.6, 0.35) * (1.0 - h) * (1.0 - h) * (1.0 - h);
}

// Both glows, as light to add along view ray rayDir (normalised), for the eye
// centred at centre; both relative to the camera, in blocks. None over the
// ball itself.
vec3 fireGlowLight(vec3 rayDir, vec3 centre) {
    vec3 eye = -centre / FIRE_RADIUS;
    float passSmooth = length(eye + rayDir * max(dot(-eye, rayDir), 0.0));
    return (fireBallGlow(passSmooth) + fireHalo(passSmooth)) * smoothstep(0.82, 1.0, passSmooth);
}

// What's drawn, as colour and alpha over the world: solid where the eye is,
// elsewhere as bright as its brightest channel, so the world shows through
// the haze; with a dither of under one colour step, so faint fades don't break
// into bands - only where there is something, so that beyond the glow stays
// exactly nothing and is discarded (a faint fragment still hides clouds and
// particles behind it).
vec4 fireBlend(vec3 rgb, float cover, ivec2 screen) {
    float something = smoothstep(0.0, 4.0 / 255.0, max(rgb.r, max(rgb.g, rgb.b)));
    rgb = max(rgb + (fireRand(ivec4(screen, 0, 260)) - 0.5) / 255.0 * something, 0.0);
    float a = clamp(max(max(rgb.r, max(rgb.g, rgb.b)), cover), 0.0, 1.0);
    return vec4(min(rgb / max(a, 1.0e-3), 1.0), a);
}

// ---------------------------------------------------------------- the eye

// The eye's colour on its layer's quad, alpha 0 where it draws nothing. Its
// own light: no shading, no light map.
#ifndef FIRE_ORIGIN
#define FIRE_ORIGIN vec3(0.0)
#endif

vec4 fireColor() {
    // rays from where the camera truly is (FIRE_ORIGIN, relative to the
    // camera's position: the view bobbing moves it), else the eye wiggles
    // against the world as the player walks
    vec3 dir = normalize(Pos - FIRE_ORIGIN);
    vec3 eye = (FIRE_ORIGIN - fireCentre) / FIRE_RADIUS;      // the camera, in radii, from the centre
    float time = fireTime * FIRE_SPEED;
    // the view's frame: x right, y up, z towards the camera
    vec3 axisZ = normalize(eye);
    vec3 up = abs(axisZ.y) > 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    vec3 axisX = normalize(cross(up, axisZ));
    vec3 axisY = cross(axisZ, axisX);
    // a pixel's width at the eye, in radii (taken before anything branches)
    float pixel = length(fwidth(dir)) * length(eye);
    ivec2 screen = ivec2(gl_FragCoord.xy);

    // where the ray crosses the plane through the centre, facing the camera
    float facing = dot(dir, -axisZ);
    vec3 crossing = eye + dir * (length(eye) / max(facing, 1.0e-3));
    vec2 plane = facing > 0.0 ? vec2(dot(crossing, axisX), dot(crossing, axisY)) : vec2(1.0e3);
    // pixelated, as Minecraft's textures are: that plane is cut into squares
    // of FIRE_PIXEL blocks, each traced once, through its middle
    vec3 rayDir = dir;
    float cell = FIRE_PIXEL / FIRE_RADIUS;
    if (facing > 0.0) {
        plane = (floor(plane / cell) + 0.5) * cell;
        dir = normalize(axisX * plane.x + axisY * plane.y - eye);
    }
    pixel = max(pixel, cell);
    // how close the true, unpixelated ray passes the centre, for the glows,
    // and the pixelated one, for the rest
    float passSmooth = length(eye + rayDir * max(dot(-eye, rayDir), 0.0));
    float pass = length(eye + dir * max(dot(-eye, dir), 0.0));

    // the almond's plane, through the centre facing along x - north-south
    float almondT = abs(rayDir.x) > 1.0e-4 ? -eye.x / rayDir.x : -1.0;
    vec2 almondPos = almondT > 0.0 ? (eye + rayDir * almondT).zy : vec2(1.0e3);
    almondPos = (floor(almondPos / cell) + 0.5) * cell;
    float side = abs(almondPos.x) / FIRE_EYE_WIDTH;     // 0 at the middle, 1 at a tip
    // its lids: round at the middle, closing to points
    float lid = FIRE_EYE_HEIGHT * max(1.0 - side * side, 0.0) * (1.0 - 0.3 * side);
    // a flat plane, it thins away as it turns edge-on - or seen from close to
    // it, its sliver would stretch across the whole sky
    float faceOn = smoothstep(0.08, 0.3, abs(rayDir.x));
    bool nearAlmond = faceOn > 0.0 && side < 1.0 && abs(almondPos.y) < lid * 1.7 + 0.1;

    // where it looks, and how fully at the viewer
    float lock;
    vec3 gaze = fireGaze(fireTime, lock);
    float flare = 1.0 + FIRE_LOCK_FLARE * lock;

    // the eye's layer draws where the ball, its flames or the almond are, its
    // glow there included; the glow's layers everywhere else. Those split the
    // pixels between them, each drawing every FIRE_GLOW_LAYERS-th in a fixed
    // pattern: drawn in whatever order, none can hide another (a layer
    // records its depth where it draws, and the game orders them by where the
    // camera stands)
    bool eyePart = passSmooth < max(1.05, FIRE_CORONA) || nearAlmond;
#ifndef FIRE_ONE_LAYER
    if ((fireLayer >= 1) == eyePart) return vec4(0.0);
    int share = ((screen.x & 1) + 2 * (screen.y & 1) + 3 * ((screen.x >> 1) & 1)) % FIRE_GLOW_LAYERS;
    if (fireLayer >= 1 && share != fireLayer - 1) return vec4(0.0);
#endif
#ifdef FIRE_NO_GLOW
    vec3 ballGlow = vec3(0.0);
    vec3 halo = vec3(0.0);
#else
    vec3 ballGlow = fireBallGlow(passSmooth) * flare;
    vec3 halo = fireHalo(passSmooth) * flare;
#endif
    // the glow alone: a few sums
    if (!eyePart) return fireBlend(ballGlow + halo, 0.0, screen);

    // ---- the ball: the original's burning shells, one inside the other,
    // turning; a dark crust drifting up over the outermost
    float b = dot(eye, dir);
    float disc = b * b - (dot(eye, eye) - 1.0);
    bool onBall = disc > 0.0 && pass < 1.0;
    vec3 ball = vec3(0.0);
    float ballCover = 1.0 - smoothstep(0.82, 1.0, pass);
    float irisClear = 1.0;
    if (onBall) {
        // where the ray meets it, in the view's frame
        vec3 hit = eye + dir * (-b - sqrt(disc));
        vec3 surface = vec3(dot(hit, axisX), dot(hit, axisY), dot(hit, axisZ));
        // the pupil's frame, on the ball: z where it looks
        vec3 gx = normalize(vec3(gaze.z, 0.0, -gaze.x));
        vec3 gy = cross(gaze, gx);
        vec2 p = vec2(dot(surface, gx), dot(surface, gy));
        float front = smoothstep(0.0, 0.25, dot(surface, gaze));
        float pDist = length(vec2(p.x * 1.6, p.y));
        irisClear = mix(1.0, smoothstep(0.18, 0.48, pDist), front);

        // the shells: fewer traced as the ball gets small on screen, the
        // rest - and any whose flames are finer than a pixel - burning as
        // brightly as they do on average (FIRE_SHELL_MEAN), so that from afar
        // it glows as it does close up. Its rim keeps burning, dimmer
        int shells = pixel > 0.08 ? 3 : pixel > 0.045 ? 5 : FIRE_SHELLS;
        float intensity = 0.0;
        float crust = 0.0;
        mat3 texStep = fireRotate(radians(11.0) * time, normalize(vec3(0.3, -0.7, 0.1)));
        mat3 windStep = fireRotate(radians(25.0) * time, vec3(1.0, 0.0, 0.0));
        mat3 tex = texStep;
        mat3 wind = windStep;
        for (int i = 1; i <= shells; i++) {
            float r = 1.0 - float(i) / 40.0;
            float di = b * b - (dot(eye, eye) - r * r);
            if (di < 0.0) break;                  // smaller ones are missed too
            vec3 at = eye + dir * (-b - sqrt(di));
            vec3 local = vec3(dot(at, axisX), dot(at, axisY), dot(at, axisZ));
            vec3 n = normalize(tex * wind * local);
            vec2 uv = vec2(atan(n.z, n.x) / radians(90.0), n.y) / float(i);
            float seen = 1.0 / max(FIRE_CELLS * pixel / (radians(90.0) * float(i)), 1.0);
            float alpha = fireNoise(uv, 1.0, i);
            float cut = 1.0 - float(i) / 6.0;
            float flame = mix(FIRE_SHELL_MEAN[i - 1], smoothstep(cut - 0.03, cut + 0.03, alpha) * 0.8 * alpha, seen);
            intensity += flame * mix(0.35, 1.0, max(0.0, local.z));
            if (i == 1) {
                // in upright streaks, thinning towards the rim, which keeps burning
                vec3 c = fireRotate(radians(FIRE_CRUST_SPEED) * time, vec3(1.0, 0.0, 0.0)) * local;
                float streaks = fireOctave(vec3(c.x * 7.0, c.y * 2.5, c.z * 7.0), 230, 7.0, pixel) * 0.6
                              + fireOctave(vec3(c.x * 15.0, c.y * 5.0, c.z * 15.0), 231, 15.0, pixel) * 0.4;
                crust = smoothstep(0.48, 0.68, streaks) * smoothstep(0.15, 0.6, local.z);
            }
            tex = texStep * tex;
            wind = windStep * wind;
        }
        for (int i = shells + 1; i <= FIRE_SHELLS; i++)
            if (pass < 1.0 - float(i) / 40.0) intensity += FIRE_SHELL_MEAN[i - 1] * mix(0.35, 1.0, max(0.0, surface.z));

        // ---- the iris's fire: streaks streaming out from the slit across
        // the ball, in layers, the slit itself kept clear - fading towards
        // the ball's rim as it turns away
        float sAngle = atan(p.y, p.x);
        float sDist = length(vec2(p.x * 1.5, p.y));
        float streams = 0.0;
        // (as the shells: fewer, and the rest as bright as on average)
        int layers = pixel > 0.06 ? 2 : 4;
        for (int i = 1; i <= 4; i++) {
            float k = 8.0 + float(i) * 2.0;
            float seen = i <= layers ? 1.0 - smoothstep(0.5, 1.0, k / max(sDist, 0.15) * pixel) : 0.0;
            float stream = FIRE_STREAM_MEAN[i - 1];
            if (seen > 0.0) {
                vec3 sc = vec3(cos(sAngle) * k, sin(sAngle) * k, sDist * (4.0 + float(i) * 1.2) - time * (2.4 + float(i) * 0.4));
                float filament = smoothstep(0.25, 0.72, fireValueNoise(sc, 210 + i * 7));
                float cut = 1.0 - float(i) / 5.0;
                stream = mix(stream, smoothstep(cut - 0.05, cut + 0.05, filament) * 0.45, seen);
            }
            streams += stream;
        }
        // a ring round the iris: past it the burning ball shows
        streams *= smoothstep(0.18, 0.48, sDist) * (1.0 - smoothstep(FIRE_IRIS_FIRE * 0.55, FIRE_IRIS_FIRE, sDist))
                 * front * max(surface.z, 0.0);

        // ---- the slit: a tall oval closing suddenly to points, its edges
        // ragged and flickering, narrowing as the eye fixes on the viewer
        float yNorm = abs(p.y) / FIRE_SLIT_HEIGHT;
        float body = pow(max(1.0 - yNorm * yNorm, 0.0), 0.38);
        float pinch = pow(max(1.0 - yNorm, 0.0), 0.45);
        float slitHalf = FIRE_SLIT_WIDTH * body * mix(1.0, pinch, smoothstep(0.55, 0.95, yNorm)) * mix(1.0, 0.75, lock);
        float flicker = fireOctave(vec3(p.y * 7.0, time * 2.5, 0.0), 240, 7.0, pixel);
        float edgeNoise = fireOctave(vec3(p.x * 12.0, p.y * 16.0, time * 1.8), 241, 16.0, pixel);
        float ragged = slitHalf * (1.0 + (mix(flicker, edgeNoise, 0.5) - 0.5) * 0.28);
        float slit = (1.0 - smoothstep(ragged * 0.35, max(ragged * 1.25, 1.0e-3), abs(p.x)))
                   * smoothstep(1.0, 0.9, yNorm) * front;

        // ---- the iris: white-hot right round the slit, and fine rays
        // streaming out from it across the ball
        float pAngle = atan(p.y, p.x);
        float rN1 = fireOctave(vec3(cos(pAngle) * 8.0, sin(pAngle) * 8.0, pDist * 4.5 - time * 2.8), 245, 8.0, pixel);
        float rN2 = fireOctave(vec3(cos(pAngle) * 22.0, sin(pAngle) * 22.0, pDist * 9.5 - time * 4.2), 246, 22.0, pixel);
        float comb1 = pow(max(sin(pAngle * 28.0 + rN1 * 2.5), 0.0), 3.8);
        float comb2 = pow(max(sin(pAngle * 56.0 + rN2 * 2.0), 0.0), 4.2);
        // the finest comb only where it's more than a blur
        float comb3 = pixel < 0.04 ? pow(max(cos(pAngle * 112.0 + rN2 * 2.0), 0.0), 4.8) : 0.15;
        float filaments = (comb1 * 0.5 + comb2 * 0.35 + comb3 * 0.25) * smoothstep(0.2, 0.72, rN1 * 0.55 + rN2 * 0.45);
        float whiteEdge = exp(-max(abs(p.x) - ragged, 0.0) * 28.0) * smoothstep(1.02, 0.92, yNorm) * (1.0 - slit);
        float iris = smoothstep(FIRE_IRIS, FIRE_IRIS * 0.25, pDist);
        float irisHeat = (whiteEdge * 1.25 + iris * (0.8 + filaments * 0.65)) * front;
        float rays = filaments * smoothstep(0.07, 0.2, pDist) * exp(-pDist * 1.35) * FIRE_RAYS * front;

        // the burning ball under the iris's fire, its crust darkening only
        // the ball, and kept off the iris; the iris on an amber ground of
        // embers, its own - on the ball, never past it
        float sphere = intensity * FIRE_BALL_HEAT * (1.0 - crust * FIRE_CRUST) * mix(0.12, 1.0, irisClear);
        float irisGround = (1.0 - smoothstep(FIRE_IRIS * 1.5, FIRE_IRIS * 3.1, sDist)) * front;
        vec3 amber = mix(vec3(0.22, 0.085, 0.01), vec3(0.36, 0.155, 0.022),
                         fireOctave(vec3(p * 5.0, time * 0.5), 238, 5.0, pixel));
        ball = fireShade(sphere + (streams * 0.75 + irisHeat + rays) * flare) + amber * irisGround;
        // the slit: deep, dark, a glint of the fire in it
        vec3 voidColor = mix(vec3(0.012, 0.004, 0.001), vec3(0.04, 0.014, 0.003), edgeNoise);
        ball = mix(ball, mix(ball * 0.12 + voidColor, voidColor, 0.75), slit * 0.94);
    }

    // ---- the corona: flames streaming out from behind the ball, all round
    // its rim, longest towards the almond's tips so the two run together
    // (from well inside the ball's edge: those flames lick in over its rim,
    // so the burning ball runs into the fire round it)
    vec3 corona = vec3(0.0);
    float coronaR = length(plane);
    if (coronaR > 0.6 && coronaR < FIRE_CORONA * 1.05) {
        float coronaAngle = atan(plane.y, plane.x);
        float coronaSide = plane.x >= 0.0 ? 1.0 : -1.0;
        vec3 cp = vec3(cos(coronaAngle) * 6.5 - coronaSide * time * 0.35, sin(coronaAngle) * 6.5,
                       log(max(coronaR, 0.45)) * 3.0 - time * FIRE_CORONA_SPEED);
        float tongues = fireValueNoise(cp, 280) * 0.45 + fireOctave(cp * 2.3 + 3.0, 281, 15.0, pixel) * 0.3
                      + fireOctave(cp * 5.4 + vec3(2.1, 5.4, 1.2), 282, 35.0, pixel) * 0.17
                      + fireOctave(cp * 11.5 + vec3(7.3, 1.8, 4.6), 283, 75.0, pixel) * 0.08;
        tongues = pow(smoothstep(0.28, 0.72, tongues), 1.2);
        float coronaReach = mix(FIRE_CORONA * 0.85, FIRE_CORONA * 1.05, pow(abs(cos(coronaAngle)), 1.1));
        corona = fireShade(tongues * (1.0 - smoothstep(0.95, coronaReach, coronaR)) * FIRE_CORONA_STRENGTH * 1.8 * flare);
    }

    // ---- the almond: pixelated on its own plane. Flames stream out from the
    // ball, and further out along it to its tips, over a faint ground, its
    // lids licked by them
    vec3 eyeFire = vec3(0.0);
    float almond = 0.0;
    if (nearAlmond && almondT > 0.0) {
        float rho = length(almondPos / vec2(FIRE_EYE_WIDTH, FIRE_EYE_HEIGHT));
        float angle = atan(almondPos.y, almondPos.x);
        float sideSign = almondPos.x >= 0.0 ? 1.0 : -1.0;
        vec3 fr = vec3(cos(angle) * 5.0, sin(angle) * 5.0, log(max(rho, 0.03)) * 2.5 - time * FIRE_EYE_SPEED);
        float radial = fireValueNoise(fr, 220) * 0.6 + fireOctave(fr * 2.2 + 7.0, 221, 11.0, pixel) * 0.4;
        // (warped by the radial flames, so the lattice the noise is made on
        // doesn't show as bars)
        vec3 fs = vec3(almondPos.x * 1.6 - sideSign * time * FIRE_SIDE_SPEED * 1.5,
                       almondPos.y * 3.5 + (radial - 0.5) * 1.6 - time * 0.35, time * 0.45 + radial);
        float sideFlame = fireValueNoise(fs, 224) * 0.4 + fireOctave(fs * 2.4 + 4.0, 225, 8.4, pixel) * 0.3
                        + fireOctave(fs * 5.6 + vec3(1.7, 8.3, 3.1), 226, 19.6, pixel) * 0.2
                        + fireOctave(fs * 12.5 + vec3(5.2, 2.1, 7.9), 227, 43.8, pixel) * 0.1;
        sideFlame = pow(smoothstep(0.18, 0.78, sideFlame), 1.25);
        float flames = mix(radial, sideFlame, smoothstep(0.12, 0.55, side));
        // fine threads along the streams out to the tips
        float threads = (pow(max(sin(almondPos.y * 16.0 + sideFlame * 3.2), 0.0), 2.6) * 0.55
                       + pow(max(cos(almondPos.y * 36.0 + flames * 3.0), 0.0), 3.0) * 0.45) * smoothstep(0.2, 0.7, side);
        vec3 ew = vec3(almondPos.x * 4.0 - sideSign * time * FIRE_SIDE_SPEED * 1.7, almondPos.y * 7.0 - time * 0.7, time * 0.5);
        float wisps = fireValueNoise(ew, 230) * 0.6 + fireOctave(ew * 2.5 + 2.0, 231, 17.5, pixel) * 0.4;
        float inEye = abs(almondPos.y) / max(lid, 1.0e-3) - (flames - 0.5) * 0.5 - (wisps - 0.5) * 0.2;
        // soft lids; the tips fade only at their very ends
        almond = (1.0 - smoothstep(0.15, 1.3, inEye)) * (1.0 - smoothstep(0.8, 1.0, side)) * faceOn;
        float heat = almond * (0.15 + smoothstep(0.3, 0.8, flames) + threads * 0.4)
                   * mix(1.5, 0.6, clamp(rho, 0.0, 1.0)) * FIRE_EYE_STRENGTH;
        // its ground and solidity fall away faster than its flames, so its
        // edge thins out rather than ending
        eyeFire = fireShade(heat) + vec3(0.12, 0.03, 0.005) * almond * almond;
    }
    float eyeCover = almond * almond * 0.3;

    // the ball, the almond in front of or behind it, and the glow round the
    // ball's edge; behind, the almond's flames run on over the ball's rim,
    // joining the two - but never over the iris
    float ballT = onBall ? -b - sqrt(disc) : 1.0e9;
    vec3 rgb;
    float cover = max(ballCover, eyeCover);
    if (almondT > 0.0 && almondT < ballT && pass > 0.9) {
        float eyeAlpha = clamp(max(max(eyeFire.r, max(eyeFire.g, eyeFire.b)), eyeCover), 0.0, 1.0);
        vec3 behind = ball * ballCover + (ballGlow + corona) * (1.0 - ballCover);
        rgb = eyeFire + behind * (1.0 - eyeAlpha);
    } else {
        float rim = smoothstep(0.55, 1.0, pass) * irisClear;
        vec3 rimFlames = corona * FIRE_RIM_FLAMES * smoothstep(0.6, 0.97, pass) * irisClear;
        rgb = mix(eyeFire + ballGlow + corona, ball + eyeFire * rim * 0.5 + rimFlames, ballCover);
    }
    rgb += halo * (1.0 - cover);
    return fireBlend(rgb, cover, screen);
}
