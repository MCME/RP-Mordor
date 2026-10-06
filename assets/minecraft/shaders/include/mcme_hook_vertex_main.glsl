// the fire eye. Its clock: under vanilla GameTime, the day's fraction; under
// Sodium milliseconds since its region was made, so it restarts when the
// region is
#define FIRE_MODELVIEW MCME_MODELVIEW
#ifdef MCME_PROJECTION
#define FIRE_PROJECTION MCME_PROJECTION
#endif
#define FIRE_SECONDS MCME_SECONDS
#moj_import <minecraft:fire_eye_main.glsl>
