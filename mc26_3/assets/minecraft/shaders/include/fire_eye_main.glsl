// 26.3's copy of assets/minecraft/shaders/include/fire_eye_main.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_FIRE_EYE_MAIN_GLSL
#define MCME_FIRE_EYE_MAIN_GLSL
// The fire eye's vertex part, imported into main() right after objmc_main.glsl,
// whose atlasSize, uv (the texel the face's UV is in), uvHigh (which corner of
// it the vertex has) and isCustom it reads. Shared by vanilla's terrain.vsh and
// Sodium's block_layer_opaque.vsh: Position is the vertex's section-local
// position, Pos its position relative to the camera, FIRE_MODELVIEW the
// model-view matrix and FIRE_SECONDS a clock in seconds, set there. Shader
// packs set those themselves, and FIRE_BLOCK_CENTRE, the block's centre
// relative to the camera, too.
//
// The eye's model is small faces in its block's middle (models/block/
// fire_eye.json), each pointing - UV inside one texel - at a descriptor in its
// sheet: an alpha of 254, so the faces go in the translucent layer, and an
// offset back to the sheet's top-left, which holds a marker and the eye's
// signature. The first face is the eye's, the rest its glow's layers, from 1.

#ifndef FIRE_BLOCK_CENTRE
#define FIRE_BLOCK_CENTRE (floor(Position) + 0.5 + (Pos - Position))
#endif

fireLayer = -1;
fireCentre = vec3(0.0);
fireOrigin = vec3(0.0);
fireTime = FIRE_SECONDS;
if (isCustom == 0) {
    ivec4 firePointer = ivec4(texelFetch(Sampler0, uv, 0) * 255.0 + 0.5);
    if (firePointer.a == 254) {
        ivec2 fireSheet = uv - ivec2(firePointer.r * 16 + (firePointer.g >> 4), (firePointer.g & 15) * 256 + firePointer.b);
        if (all(greaterThanEqual(fireSheet, ivec2(0)))
                && ivec4(texelFetch(Sampler0, fireSheet, 0) * 255.0 + 0.5) == ivec4(98, 76, 54, 255)
                && ivec4(texelFetch(Sampler0, fireSheet + ivec2(1, 0), 0) * 255.0 + 0.5) == ivec4(13, 57, 93, 255))
            fireLayer = uv.x - fireSheet.x - FIRE_DESCRIPTOR_X;
    }
}

// Each face becomes a quad facing the camera, covering what it draws. The
// eye's - its ball and almond - sits at the depth of the block's centre, so
// terrain in front of the centre still hides it. The glow is light in the air
// round it: FIRE_GLOW_LAYERS thin layers spread over FIRE_GLOW_DEPTH radii
// behind the centre, each drawing all of it on its own share of the screen's
// pixels. Terrain well behind the eye has all of them over it, terrain just
// behind it some, terrain in front none - so the glow fades in over depth,
// dithered, rather than being cut off where blocks cross one. Each corner is
// told apart by its texture coordinate, as objmc's are.
if (fireLayer >= 0) {
    fireCentre = FIRE_BLOCK_CENTRE;                             // camera-relative
#ifdef FIRE_PROJECTION
    // where the camera truly is: the game puts its view bobbing into the
    // projection, moving it off the origin as the player walks - the centre
    // the projection draws towards, which it maps to w = 0
    vec4 fireEyePoint = inverse(FIRE_PROJECTION * FIRE_MODELVIEW) * vec4(0.0, 0.0, 1.0, 0.0);
    if (abs(fireEyePoint.w) > 1.0e-6) fireOrigin = fireEyePoint.xyz / fireEyePoint.w;
#endif
    float reach = FIRE_RADIUS * (fireLayer >= 1 ? FIRE_HALO : max(FIRE_EYE_WIDTH, 1.0) * 1.1);
    vec3 centre = (FIRE_MODELVIEW * vec4(fireCentre, 1.0)).xyz;  // view space, looking down -z
    float depth = max(-centre.z, 0.3);
    vec2 lo, hi;
    if (-centre.z - reach > 0.3) {
        // all of it ahead: where its nearest and furthest points project
        // onto the quad's plane bounds it
        float nearScale = depth / (-centre.z - reach);
        float farScale = depth / (-centre.z + reach);
        vec2 a = centre.xy - reach, b = centre.xy + reach;
        lo = min(a * nearScale, a * farScale);
        hi = max(b * nearScale, b * farScale);
    } else {
        // around the camera: the whole view
        lo = vec2(-4.0 * depth);
        hi = vec2(4.0 * depth);
    }
    // corners 0-3 run (low u, low v), (low u, high v), (high u, high v),
    // (high u, low v): high v at the bottom keeps them anticlockwise on
    // screen, facing the camera
    vec3 corner = vec3(uvHigh.x ? hi.x : lo.x, uvHigh.y ? lo.y : hi.y, -depth);
    // a glow layer, moved back along the camera's rays: the same pixels,
    // further off
    if (fireLayer >= 1) {
        float behind = FIRE_RADIUS * FIRE_GLOW_DEPTH * (float(fireLayer) - 0.5) / float(FIRE_GLOW_LAYERS);
        corner *= (depth + behind) / depth;
    }
    Pos = (inverse(FIRE_MODELVIEW) * vec4(corner, 1.0)).xyz;
}
#endif
