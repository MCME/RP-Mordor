// The ice's settings (ice.glsl). See ice.glsl for what it is.

#define ICE_PIXEL (1.0 / 16.0)       // its pixels' size, in blocks, as a 16px texture's

// inside it, seen through its faces in layers, as the lava's and water's are
#define ICE_LAYERS 5                 // how many (up to 6)
#define ICE_DEPTH 0.9                // how deep the last lies, in blocks
#define ICE_FRACTURES 0.6            // how bright the cracks frozen into it are...
#define ICE_FRACTURE_SIZE 2.0        // ...and how far apart, roughly, in blocks (a power of two)
#define ICE_BUBBLES 0.12             // how many of its small cells hold a trapped bubble, 0 to 1

// packed ice: whiter, cloudier; blue ice: deeper, clearer
#define ICE_PACKED_SURFACE vec3(0.66, 0.78, 0.96)
#define ICE_PACKED_DEEP vec3(0.4, 0.55, 0.86)
#define ICE_PACKED_CLOUD 0.55
#define ICE_BLUE_SURFACE vec3(0.45, 0.64, 0.98)
#define ICE_BLUE_DEEP vec3(0.1, 0.27, 0.78)
#define ICE_BLUE_CLOUD 0.2

#define ICE_SHEEN 0.35               // how much of the sky's colour it takes, looking along it

// frost where it meets other blocks - by their shading, as the water's shores
#define ICE_FROST 0.22               // how far it reaches, in blocks
#define ICE_FROST_COLOR vec3(0.9, 0.95, 1.0)
#define ICE_SPARKLE 0.06             // how many of the frost's pixels glint, now and then
