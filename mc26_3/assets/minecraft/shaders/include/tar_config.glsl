// 26.3's copy of assets/minecraft/shaders/include/tar_config.glsl, translated by ResourcePackScripts' shader_base.py: don't edit it.
#ifndef MCME_TAR_CONFIG_GLSL
#define MCME_TAR_CONFIG_GLSL
// The tar's settings (tar.glsl). See tar.glsl for what it is.

#define TAR_PIXEL (1.0 / 16.0)       // its pixels' size, in blocks, as a 16px texture's

#define TAR_COLOR vec3(0.11, 0.1, 0.085)    // its colour, near black...
#define TAR_SWIRL 0.35               // ...and how much its slow swirls lighten and darken it
#define TAR_GLOSS 0.12               // how bright the gloss along the swirls' ridges is
#define TAR_GLOSS_COLOR vec3(0.55, 0.58, 0.62)

// how its swirls slowly change, in place - a pit doesn't flow: whole turns
// a day, so that it is as it was when the day's clock starts over
#define TAR_CHANGE 2                 // (a swirl takes about 40 seconds to become another)

// the detail on it
#define TAR_SKIN 0.12                // how dark the fine wrinkles in its skin are
#define TAR_GRIT 0.03                // how many of its pixels hold a speck of grit or ash, 0 to 1
#define TAR_GRIT_COLOR vec3(0.2, 0.18, 0.15)

// bubbles swelling slowly and bursting, rings spreading out after
#define TAR_BUBBLE_SPACING 2.0       // at most one at a time in each square this wide, in blocks (a power of two)
#define TAR_BUBBLES 0.4              // in how many of them, 0 to 1
#define TAR_BUBBLE_SIZE 0.35         // how wide the biggest are across, in blocks

// a dark, dull crust along its banks, where other blocks crowd it
#define TAR_EDGE 0.4                 // how far in it reaches, about, in blocks
#define TAR_EDGE_COLOR vec3(0.035, 0.03, 0.025)
#endif
