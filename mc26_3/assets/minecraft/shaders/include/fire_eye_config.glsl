// 26.3's copy of assets/minecraft/shaders/include/fire_eye_config.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_FIRE_EYE_CONFIG_GLSL
#define MCME_FIRE_EYE_CONFIG_GLSL
// The fire eye's settings, shared by its vertex part (fire_eye_main.glsl) and
// its fragment part (fire_eye.glsl). See fire_eye.glsl for what it is.

// Where its sheet's descriptors start, along their row: the eye's own, then
// one per glow layer (assets/minecraft/textures/block/fire_eye.png).
#define FIRE_DESCRIPTOR_X 8

// Where the eye is - its block - for what draws it from afar: shader packs
// (patch_shaderpack.py) and, with a distant terrain mod, the sky (core/sky.fsh)...
#define FIRE_EYE_BLOCK ivec3(12447, 678, 2629)
// ...past this distance, in blocks, beyond which the eye's chunk is never sent
// and its block never drawn (far_terrain.glsl, imported first)
#define FIRE_HANDOVER SERVER_VIEW_DISTANCE
// ...where it takes on Distant Horizons' fog at its own distance, not that of
// the LODs behind it: all of it up to FIRE_FOG_LOW degrees above the horizon,
// none from FIRE_FOG_HIGH up, where it's over the sky, not the fogged land
#define FIRE_FOG_LOW 3.0
#define FIRE_FOG_HIGH 8.0

#define FIRE_RADIUS 10.5             // the ball's radius, in blocks; everything else scales with it
#define FIRE_PIXEL 0.25              // its pixels' size, in blocks

// ---- the ball: burning shells, one inside the other, turning
#define FIRE_SHELLS 8                // how many (up to 9); fewer are traced as it gets small on screen
#define FIRE_CELLS 64.0              // how fine their flames are: the noise's cells per unit
#define FIRE_SPEED 1.0               // how fast they turn
#define FIRE_BALL_HEAT 0.45          // how hot they burn under the iris: higher is yellower
#define FIRE_CRUST 0.45              // how dark the crust drifting over it is...
#define FIRE_CRUST_SPEED 18.0        // ...and how fast it drifts up, in degrees a second

// ---- the pupil, on the ball, and the iris round it
#define FIRE_SLIT_WIDTH 0.16         // the slit: half its width at the middle...
#define FIRE_SLIT_HEIGHT 0.63        // ...and half its height, in radii
#define FIRE_IRIS 0.2                // how far the white-hot iris reaches round it, in radii
#define FIRE_IRIS_FIRE 0.95          // how far the fire streaming out from it reaches, in radii
#define FIRE_RAYS 0.95               // how bright the fine rays streaming out from it are

// ---- where it looks: mostly away from whoever sees it, to a side and down - all
// it watches lies below it - now and then right at them
#define FIRE_LOOK 0.6                // how far it looks to a side at most, as the tangent of the angle (0.6 is 31 degrees)...
#define FIRE_LOOK_DOWN 0.5           // ...and down (0.5 is 27 degrees)...
#define FIRE_LOOK_HOLD 5.0           // ...how long it holds each glance, in seconds...
#define FIRE_LOOK_DART 0.8           // ...how long it takes to move to the next...
#define FIRE_LOCK_CHANCE 0.05        // ...how often it turns on the viewer instead, 0 to 1...
#define FIRE_LOCK_HOLD 2             // ...holding that this many glances long...
#define FIRE_LOCK_SNAP 0.25          // ...turning to them this fast, in seconds...
#define FIRE_LOCK_FLARE 0.45         // ...and flaring this much brighter while it does

// ---- the almond round the ball, fixed in the world, running north-south
#define FIRE_EYE_WIDTH 2.6           // half its width...
#define FIRE_EYE_HEIGHT 1.1          // ...and half its height, in radii
#define FIRE_EYE_SPEED 0.7           // how fast its flames stream out from the ball
#define FIRE_SIDE_SPEED 1.25         // how fast they stream to its tips
#define FIRE_EYE_STRENGTH 1.1        // how bright they are

// ---- flames streaming out from behind the ball
#define FIRE_CORONA 1.8              // how far, in radii...
#define FIRE_CORONA_STRENGTH 1.0     // ...how bright...
#define FIRE_CORONA_SPEED 0.8        // ...and how fast they stream
#define FIRE_RIM_FLAMES 0.7          // how brightly they lick in over the ball's rim, blending it into them

// ---- the glow
#define FIRE_GLOW 8.0                // how far the glow reaches, in radii; keep it past FIRE_EYE_WIDTH and under FIRE_HALO
#define FIRE_GLOW_FALLOFF 0.8        // how quickly it eases away from the ball; lower spreads it wider
#define FIRE_GLOW_STRENGTH 0.5       // how bright the glow round the ball is; it also dims what's behind
#define FIRE_HALO 11.0               // a second, fainter glow: how far it reaches, in radii...
#define FIRE_HALO_STRENGTH 0.3       // ...and how bright it is at the ball
#define FIRE_GLOW_LAYERS 4           // the glow is drawn in this many layers (2 or 4 split the pixels evenly; the sheet and model have 4)...
#define FIRE_GLOW_DEPTH 6.0          // ...spread over this many radii behind its centre

// for shader packs' recipes written against the old names
#define FIRE_EYE_PULL FIRE_EYE_SPEED
#endif
