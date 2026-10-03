// The fire eye: a burning ball some FIRE_RADIUS blocks round its block (after
// Shadertoy wdVXWR), with a dark crust drifting up over it and a slit pupil
// that looks about, in a fiery almond fixed in the world, with flames
// streaming out from behind it and a wide glow. All of it is ray traced per
// pixel on camera-facing quads that its vertex part (fire_eye_main.glsl)
// makes of its model's faces; fireColor() is its colour there.
//
// Shared by vanilla's terrain.fsh and Sodium's block_layer_opaque.fsh. Pos is
// the fragment's position relative to the camera.
//
// Shader packs can't draw the eye's wide glow on quads: theirs cut off the fog
// and clouds behind anything translucent. They define FIRE_NO_GLOW, so that
// fireColor() is only the eye, and add fireGlowLight() over their finished
// scene instead.

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

vec3 fireShade(float x) {
    // Rich, warm fiery orange with golden highlights (orange-leaning, not overly yellow)
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

// How far the eye's block hands over to the sky's eye, at distance blocks
// from the camera: 0 well inside FIRE_HANDOVER, 1 at it - over its last chunk.
float fireHandover(float distance) {
    return smoothstep(FIRE_HANDOVER - 16.0, FIRE_HANDOVER, distance);
}

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

// The eye's colour on its layer's quad, alpha 0 where it draws nothing. Its
// own light: no shading, no light map.
vec4 fireColor() {
    vec3 dir = normalize(Pos);
    vec3 eye = -fireCentre / FIRE_RADIUS;      // the camera, in radii, from the centre
    float time = fireTime * FIRE_SPEED;
    // the view's frame: x right, y up, z towards the camera
    vec3 axisZ = normalize(eye);
    vec3 up = abs(axisZ.y) > 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    vec3 axisX = normalize(cross(up, axisZ));
    vec3 axisY = cross(axisZ, axisX);
    // a pixel's width on the ball's surface, in radians round it
    float pixel = length(fwidth(dir)) * length(eye);

    // where the ray crosses the plane through the centre, facing the camera:
    // the pupil is drawn there, in radii
    float facing = dot(dir, -axisZ);
    vec3 crossing = eye + dir * (length(eye) / max(facing, 1.0e-3));
    vec2 plane = facing > 0.0 ? vec2(dot(crossing, axisX), dot(crossing, axisY)) : vec2(1.0e3);
    // pixelated, as Minecraft's textures are: that plane is cut into squares
    // of FIRE_PIXEL blocks, each traced once, through its middle, for the
    // ball, its pupil and its glow
    vec3 rayDir = dir;
    float cell = FIRE_PIXEL / FIRE_RADIUS;
    if (facing > 0.0) {
        plane = (floor(plane / cell) + 0.5) * cell;
        dir = normalize(axisX * plane.x + axisY * plane.y - eye);
    }
    pixel = max(pixel, cell);
    // how close the true, unpixelated ray passes the centre, for the glows
    float passSmooth = length(eye + rayDir * max(dot(-eye, rayDir), 0.0));
    float along = max(dot(-eye, dir), 0.0);
    float pass = length(eye + dir * along);    // how close the ray passes the centre

    // Fallback defaults if not set in config
#ifndef FIRE_EYE_SPEED
#define FIRE_EYE_SPEED FIRE_EYE_PULL
#endif
#ifndef FIRE_SIDE_SPEED
#define FIRE_SIDE_SPEED 1.2
#endif

    // ---- the slit pupil: tall, black, its edges flickering, a blazing white rim.
    // It looks about: every FIRE_LOOK_HOLD seconds it moves to a new spot -
    // further sideways than up or down, now and then back to the middle - and
    // holds there, narrowing as it turns away.
    float glances = fireTime / FIRE_LOOK_HOLD;
    int glance = int(floor(glances));
    vec2 lookFrom = fireRand(ivec4(glance - 1, 2, 0, 270)) < 0.3 ? vec2(0.0)
                  : vec2(fireRand(ivec4(glance - 1, 0, 0, 270)), fireRand(ivec4(glance - 1, 1, 0, 270))) * 2.0 - 1.0;
    vec2 lookTo = fireRand(ivec4(glance, 2, 0, 270)) < 0.3 ? vec2(0.0)
                : vec2(fireRand(ivec4(glance, 0, 0, 270)), fireRand(ivec4(glance, 1, 0, 270))) * 2.0 - 1.0;
    float dart = smoothstep(0.0, FIRE_LOOK_DART / FIRE_LOOK_HOLD, fract(glances));
    vec2 look = mix(lookFrom, lookTo, dart) * vec2(FIRE_LOOK, FIRE_LOOK * 0.5);
    vec2 pupil = plane - look;
    // Full oval body that suddenly converges into pointed ends:
    float yNorm = abs(pupil.y) / FIRE_SLIT_HEIGHT;
    float body = pow(max(1.0 - yNorm * yNorm, 0.0), 0.38);
    float suddenPinch = pow(max(1.0 - yNorm, 0.0), 0.45);
    float ovalTaper = body * mix(1.0, suddenPinch, smoothstep(0.55, 0.95, yNorm));
    float slitHalf = FIRE_SLIT_WIDTH * ovalTaper * sqrt(max(1.0 - dot(look, look), 0.3));

    // Organic serration / flicker along the slit edge:
    float flicker = fireValueNoise(vec3(pupil.y * 7.0, time * 2.5, 0.0), 240);
    float slitEdgeNoise = fireValueNoise(vec3(pupil.x * 12.0, pupil.y * 16.0, time * 1.8), 241);
    float edgeJitter = (mix(flicker, slitEdgeNoise, 0.5) - 0.5) * 0.28;
    float raggedSlit = slitHalf * (1.0 + edgeJitter);

    // Soft, continuous tapering at top and bottom - no hard cut-off or clipping:
    float yTipFade = smoothstep(1.0, 0.90, yNorm);
    float slit = (1.0 - smoothstep(raggedSlit * 0.35, max(raggedSlit * 1.25, 1.0e-3), abs(pupil.x))) * yTipFade;

    // ---- flames radiating out from the pupil / iris:
    // Polar coordinates centered on the pupil. Negative time drives wave fronts
    // continuously OUTWARD from the slit pupil across the iris and fiery ball.
    float pAngle = atan(pupil.y, pupil.x);
    float pDist = length(vec2(pupil.x * 1.6, pupil.y));

    // Multi-octave fine radial striations for sharp, delicate thread-like rays:
    vec3 ray1 = vec3(cos(pAngle) * 8.0, sin(pAngle) * 8.0, pDist * 4.5 - time * 2.8);
    vec3 ray2 = vec3(cos(pAngle) * 22.0, sin(pAngle) * 22.0, pDist * 9.5 - time * 4.2);
    vec3 ray3 = vec3(cos(pAngle) * 52.0, sin(pAngle) * 52.0, pDist * 18.0 - time * 5.8);
    float rN1 = fireValueNoise(ray1, 245);
    float rN2 = fireValueNoise(ray2, 246);
    float rN3 = fireValueNoise(ray3, 247);

    // Ultra-fine, razor-thin filament comb harmonics (high powers prevent thick blown-out bars):
    float comb1 = pow(max(sin(pAngle * 28.0 + rN1 * 2.5), 0.0), 3.8);
    float comb2 = pow(max(sin(pAngle * 56.0 + rN2 * 2.0), 0.0), 4.2);
    float comb3 = pow(max(cos(pAngle * 112.0 + rN3 * 2.0), 0.0), 4.8);
    float fineFilaments = (comb1 * 0.5 + comb2 * 0.35 + comb3 * 0.25) * smoothstep(0.2, 0.72, rN1 * 0.55 + rN2 * 0.45);

    // Iris directly around pupil is bright, with a thin razor white-hot rim kissing the slit without clipping:
    float whiteEdge = exp(-max(abs(pupil.x) - raggedSlit, 0.0) * 28.0) * smoothstep(1.02, 0.92, yNorm) * (1.0 - slit);
    float irisRing = smoothstep(0.20, 0.05, pDist);
    float irisBrightHeat = whiteEdge * 1.25 + irisRing * (0.8 + fineFilaments * 0.65);

    // Delicate radiating rays streaming outward (calibrated heat prevents blowout):
    float radiatingRays = fineFilaments * smoothstep(0.07, 0.20, pDist) * exp(-pDist * 1.35) * 0.95;

    // Eye-shaped amber background: rounder silhouette, sized to the radiating fire effect
    // with a broad, soft fade extending past it, converging to points ONLY on left and right:
    float darkEyeW = 1.10;
    float darkEyeH = 0.90;
    vec2 bgP = pupil;
    float u = bgP.x / darkEyeW;
    float v = bgP.y / darkEyeH;
    float eyePointed = u * u + abs(v);
    float eyeRound = u * u + v * v;
    float darkEyeShape = mix(eyePointed, eyeRound, 0.35);

    // Soft, gradual falloff past the radiating fire effect, maintaining solid visibility within:
    float edgeNoise = fireValueNoise(vec3(bgP * 4.0, time * 0.5), 243);
    float falloff = smoothstep(0.60, 1.55 + 0.12 * (edgeNoise - 0.5), darkEyeShape);
    float darkEyeAlpha = pow(max(1.0 - falloff, 0.0), 1.2);

    // Smoldering amber/orange ember ground, rich and clearly visible within the iris:
    float bgNoise = fireValueNoise(vec3(pupil * 5.0, time * 0.5), 238);
    vec3 amberColor = mix(vec3(0.22, 0.085, 0.010), vec3(0.36, 0.155, 0.022), bgNoise);
    vec3 emberGround = amberColor * darkEyeAlpha;

    // ---- the ball: nested burning sphere shells streaming OUTWARD from the pupil
    float intensity = 0.0;
    float crust = 0.0;
    if (pass < 1.0 && fireLayer == 0) {
        for (int i = 1; i <= 6; i++) {
            float r = 1.0 - float(i) / 22.0;
            float b = dot(eye, dir);
            float disc = b * b - (dot(eye, eye) - r * r);
            if (disc < 0.0) break;
            float t = -b - sqrt(disc);
            if (t < 0.0) t = -b + sqrt(disc);
            if (t < 0.0) continue;
            vec3 hit = eye + dir * t;
            vec3 local = vec3(dot(hit, axisX), dot(hit, axisY), dot(hit, axisZ));

            // Vector from pupil on the sphere shell:
            vec2 shellP = local.xy - look;
            float sDist = length(vec2(shellP.x * 1.5, shellP.y));
            float sAngle = atan(shellP.y, shellP.x);

            // Keep the iris and pupil completely clear - no shell flames drifting in front of the iris:
            float irisClearShell = smoothstep(0.18, 0.48, sDist);

            // OUTWARD radial streaming on this shell:
            vec3 shellCoord = vec3(cos(sAngle) * (8.0 + float(i) * 2.0),
                                   sin(sAngle) * (8.0 + float(i) * 2.0),
                                   sDist * (4.0 + float(i) * 1.2) - time * (2.4 + float(i) * 0.4));
            float shellNoise = fireValueNoise(shellCoord, 210 + i * 7);

            // Radial tendril modulation on this shell:
            float shellFilament = smoothstep(0.25, 0.72, shellNoise);
            float cut = 1.0 - float(i) / 5.0;
            intensity += smoothstep(cut - 0.05, cut + 0.05, shellFilament) * 0.45 * max(0.0, local.z) * irisClearShell;

            if (i == 1) {
                // Outward-drifting ember crust, away from pupil:
                vec3 c = vec3(cos(sAngle) * 7.0, sin(sAngle) * 7.0, sDist * 4.5 - time * 1.6);
                float streaks = fireValueNoise(c, 230) * 0.6 + fireValueNoise(c * 2.2 + 3.0, 231) * 0.4;
                crust = smoothstep(0.5, 0.75, streaks) * smoothstep(0.35, 0.8, sDist) * smoothstep(0.15, 0.6, local.z) * irisClearShell;
            }
        }
    }

    // Ball color: warm amber glow blending seamlessly without a harsh black hole
    float ballHeat = intensity * 0.55 + irisBrightHeat + radiatingRays;
    vec3 ball = fireShade(ballHeat) * (1.0 - crust * FIRE_CRUST * 0.35) + emberGround * (1.0 - slit * 0.65);

    // Pupil is integrated into the fire, deep, dark, and distinctly feline/almond shaped:
    vec3 pupilVoid = mix(vec3(0.012, 0.004, 0.001), vec3(0.04, 0.014, 0.003), slitEdgeNoise);
    vec3 pupilShade = mix(ball * 0.12 + pupilVoid, pupilVoid, 0.75);
    ball = mix(ball, pupilShade, slit * 0.94);

    // Ball cover follows the eye shape and fades to transparency at the edges:
    float ballCover = darkEyeAlpha;
    // (both glows are taken from the true ray, unpixelated, so they fade
    // smoothly)
#ifdef FIRE_NO_GLOW
    vec3 ballGlow = vec3(0.0);
#else
    vec3 ballGlow = fireBallGlow(passSmooth);
#endif

    // ---- a corona: flames streaming outward from behind the ball, all round
    // its rim with a rounder, fuller silhouette; multi-octave detail for crisp licking tongues.
    // Centered on pupil so radiating flames move seamlessly with the eye:
    float coronaR = length(pupil);
    float coronaAngle = atan(pupil.y, pupil.x);
    float coronaSide = pupil.x >= 0.0 ? 1.0 : -1.0;
    vec3 cp = vec3(cos(coronaAngle) * 6.5 - coronaSide * time * 0.35,
                   sin(coronaAngle) * 6.5,
                   log(max(coronaR, 0.45)) * 3.0 - time * FIRE_CORONA_SPEED);
    float c1 = fireValueNoise(cp, 280);
    float c2 = fireValueNoise(cp * 2.3 + 3.0, 281);
    float c3 = fireValueNoise(cp * 5.4 + vec3(2.1, 5.4, 1.2), 282);
    float c4 = fireValueNoise(cp * 11.5 + vec3(7.3, 1.8, 4.6), 283);
    float c5 = fireValueNoise(cp * 23.0 + vec3(3.4, 1.2, 8.5), 284);
    float tongues = smoothstep(0.28, 0.72, c1 * 0.40 + c2 * 0.28 + c3 * 0.17 + c4 * 0.10 + c5 * 0.05);
    tongues = pow(tongues, 1.2);
    // Rounder corona shape: generous vertical reach with gentle horizontal expansion
    float coronaReach = mix(FIRE_CORONA * 0.85, FIRE_CORONA * 1.05, pow(abs(cos(coronaAngle)), 1.1));
    float coronaHeat = tongues * (1.0 - smoothstep(0.95, coronaReach, coronaR)) * FIRE_CORONA_STRENGTH;
    vec3 corona = fireShade(coronaHeat * 1.8);

    // ---- the almond round it, fixed in the world: flat in the plane through
    // the centre facing along x, running north-south. Detailed outermost flames
    // streaming outward laterally to the sides, converging quickly into sharp spear tips.
    float almondT = abs(rayDir.x) > 1.0e-4 ? -eye.x / rayDir.x : -1.0;
    vec2 almondPos = almondT > 0.0 ? (eye + rayDir * almondT).zy : vec2(1.0e3);
    almondPos = (floor(almondPos / cell) + 0.5) * cell;
    float rho = length(almondPos / vec2(FIRE_EYE_WIDTH, FIRE_EYE_HEIGHT));
    float angle = atan(almondPos.y, almondPos.x);
    float sideSign = almondPos.x >= 0.0 ? 1.0 : -1.0;
    float sideNorm = abs(almondPos.x) / FIRE_EYE_WIDTH;

    // Detailed multi-octave radial flame motion (moving AWAY from center: - time * speed):
    vec3 fpRadial = vec3(cos(angle) * 5.0, sin(angle) * 5.0,
                         log(max(rho, 0.03)) * 2.5 - time * FIRE_EYE_SPEED);
    float r1 = fireValueNoise(fpRadial, 220);
    float r2 = fireValueNoise(fpRadial * 2.2 + 7.0, 221);
    float r3 = fireValueNoise(fpRadial * 5.2 + vec3(3.2, 1.4, 5.7), 222);
    float radialFlame = r1 * 0.5 + r2 * 0.34 + r3 * 0.16;

    // Rich multi-octave lateral streaming towards the sides with 6 noise octaves:
    vec3 fpSide = vec3(almondPos.x * 1.6 - sideSign * time * (FIRE_SIDE_SPEED * 1.5),
                       almondPos.y * 3.5 - time * 0.35,
                       time * 0.45);
    float s1 = fireValueNoise(fpSide, 224);
    float s2 = fireValueNoise(fpSide * 2.4 + 4.0, 225);
    float s3 = fireValueNoise(fpSide * 5.6 + vec3(1.7, 8.3, 3.1), 226);
    float s4 = fireValueNoise(fpSide * 12.5 + vec3(5.2, 2.1, 7.9), 227);
    float s5 = fireValueNoise(vec3(almondPos.x * 8.0 - sideSign * time * 2.5, almondPos.y * 22.0, time * 1.2), 228);
    float s6 = fireValueNoise(vec3(almondPos.x * 16.0 - sideSign * time * 3.8, almondPos.y * 45.0, time * 2.0), 229);
    float sideFlame = s1 * 0.32 + s2 * 0.26 + s3 * 0.18 + s4 * 0.12 + s5 * 0.08 + s6 * 0.04;
    sideFlame = pow(smoothstep(0.18, 0.78, sideFlame), 1.25);

    // Fine lateral combed horizontal filaments along the outgoing streams:
    float sideComb1 = pow(max(sin(almondPos.y * 16.0 + sideFlame * 3.2), 0.0), 2.6);
    float sideComb2 = pow(max(cos(almondPos.y * 36.0 + s3 * 3.0), 0.0), 3.0);
    float sideFilaments = (sideComb1 * 0.55 + sideComb2 * 0.45) * smoothstep(0.2, 0.7, sideNorm);

    // Blend radial expansion near center into strong lateral flaring towards the sides:
    float flames = mix(radialFlame, sideFlame, smoothstep(0.12, 0.55, sideNorm));

    // Eyelid curve converging more quickly into a sharp spear point towards the sides:
    float taper = max(1.0 - sideNorm, 0.0);
    float taperQuick = pow(taper, 1.45);
    // Vertical pinch tightens rapidly starting close to the center so it converges quickly:
    float tipPinch = mix(1.0, 0.22, smoothstep(0.18, 0.82, sideNorm));
    float lid = FIRE_EYE_HEIGHT * taperQuick * (0.75 + 0.5 * taper) * tipPinch;
    float inEye = abs(almondPos.y) / max(lid, 1.0e-3);

    // High-frequency edge wisps along the converging tips with 3 octaves:
    vec3 edgeP = vec3(almondPos.x * 4.0 - sideSign * time * (FIRE_SIDE_SPEED * 1.7),
                      almondPos.y * 7.0 - time * 0.7,
                      time * 0.5);
    float edgeWisps = fireValueNoise(edgeP, 230) * 0.52 + fireValueNoise(edgeP * 2.5 + 2.0, 231) * 0.32 + fireValueNoise(edgeP * 5.8 + 4.5, 232) * 0.16;
    float fireBoundary = inEye - (flames - 0.5) * 0.42 - (edgeWisps - 0.5) * 0.22;

    // The flames taper and converge into slender points that go slightly less out:
    float sideTaper = smoothstep(1.0, 0.88, sideNorm);
    float irisAlmondOpening = smoothstep(0.25, 0.70, rho);
    float almondFire = (1.0 - smoothstep(0.2, 0.95, fireBoundary)) * sideTaper * irisAlmondOpening;
    float streaks = smoothstep(0.28, 0.8, flames) + sideFilaments * 0.4;

    float heat = almondFire * (0.28 + streaks * 1.15) * mix(1.5, 0.7, clamp(rho, 0.0, 1.0)) * FIRE_EYE_STRENGTH;

    // Clean fiery edge in warm glowing amber tones:
    vec3 eyeFire = fireShade(heat) * almondFire + vec3(0.12, 0.035, 0.005) * almondFire * almondFire;
    float eyeCover = almondFire * almondFire * 0.35;
    float almond = almondFire;

    // the layers split the view: the eye's draws where the ball or almond is,
    // all its glow included; the glow's layers everywhere else. Those split
    // the pixels between them, each drawing every FIRE_GLOW_LAYERS-th in a
    // fixed pattern: drawn in whatever order, none can hide another (a layer
    // records its depth where it draws, and the game orders them by where the
    // camera stands)
    bool eyePart = passSmooth < max(1.05, FIRE_CORONA + FIRE_LOOK) || almond > 0.0;
    if ((fireLayer >= 1) == eyePart) return vec4(0.0);
    ivec2 screen = ivec2(gl_FragCoord.xy);
    int share = ((screen.x & 1) + 2 * (screen.y & 1) + 3 * ((screen.x >> 1) & 1)) % FIRE_GLOW_LAYERS;
    if (fireLayer >= 1 && share != fireLayer - 1) return vec4(0.0);

    // the ball, the almond in front of or behind it, and the glow round the
    // ball's edge; behind, the almond's flames run on over the ball's rim,
    // joining the two. The iris and pupil on the ball are ALWAYS in front of the flames.
    float b = dot(eye, rayDir);
    float disc = b * b - (dot(eye, eye) - 1.0);
    float ballT = disc > 0.0 ? -b - sqrt(disc) : 1.0e9;
    vec3 rgb;
    float cover = max(ballCover, eyeCover);
    float irisClear = smoothstep(0.22, 0.60, pDist);
    float rim = smoothstep(0.35, 0.95, pass) * irisClear;
    vec3 eyeOuter = eyeFire + ballGlow + corona;
    if (almondT > 0.0 && almondT < ballT && pass > 0.9) {
        float eyeAlpha = clamp(max(max(eyeFire.r, max(eyeFire.g, eyeFire.b)), eyeCover), 0.0, 1.0);
        vec3 behind = ball * ballCover + (ballGlow + corona) * (1.0 - ballCover);
        rgb = eyeFire + behind * (1.0 - eyeAlpha);
    } else {
        rgb = mix(eyeOuter, ball + eyeFire * rim * 0.4, ballCover);
    }

    // the second, larger glow
#ifndef FIRE_NO_GLOW
    rgb += fireHalo(passSmooth) * (1.0 - cover);
#endif

    // a dither of under one colour step, so faint fades don't break into
    // bands - only where there is something, so that beyond the glow stays
    // exactly nothing and is discarded (a faint fragment still hides clouds
    // and particles behind it)
    float something = smoothstep(0.0, 4.0 / 255.0, max(rgb.r, max(rgb.g, rgb.b)));
    rgb = max(rgb + (fireRand(ivec4(screen, 0, 260)) - 0.5) / 255.0 * something, 0.0);

    // blended over the world: solid where the eye is, elsewhere as bright as
    // its brightest channel, so the world shows through the haze
    float a = clamp(max(max(rgb.r, max(rgb.g, rgb.b)), cover), 0.0, 1.0);
    return vec4(min(rgb / max(a, 1.0e-3), 1.0), a);
}
