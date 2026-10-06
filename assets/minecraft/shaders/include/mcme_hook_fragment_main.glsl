// lava: its own light, with only the game's shading of its sides. The base
// has told which fluid the face is (fluid) and where on it (fluidHere), and
// drawn its water.
if ((fluid == LAVA_STILL || fluid == LAVA_FLOWING) && fireLayer < 0) {
    color = vec4(lavaColor(fluid, fluidHere, MCME_SECONDS) * mix(vec3(1.0), vertexColor.rgb, LAVA_SHADING), 1.0);
}
// ice: seen into, lit and shaded as any block - its frost by its face's own
// shade, not the occlusion that puts it there
if (fluid == ICE && fireLayer < 0) {
    IceLook ice = iceLook(fluidHere, MCME_SECONDS, shore);
    vec3 open = vertexColor.rgb / max(max(vertexColor.r, max(vertexColor.g, vertexColor.b)), 1.0e-3) * shore.open;
    color = vec4(ice.color * mix(vertexColor.rgb, open, ice.frost) * lightColor.rgb, ice.alpha);
}
// tar: lit and shaded as any block
if (fluid == TAR && fireLayer < 0) {
    color = vec4(tarColor(fluidHere, MCME_SECONDS, shore) * vertexColor.rgb * lightColor.rgb, 1.0);
}
// the fire eye: its own light, no shading, no light map. With a distant
// terrain mod the sky draws it from FIRE_HANDOVER on (core/sky.fsh), where
// this block can no longer be: it hands over, and past that costs nothing
if (fireLayer >= 0) {
    float fireHanded = farTerrain(MCME_FOG_START) ? fireHandover(length(fireCentre)) : 0.0;
    if (fireHanded >= 1.0) discard;
    fireTime = MCME_SECONDS;
    color = fireColor();
    color.a *= 1.0 - fireHanded;
    if (color.a <= 0.0) discard;              // only what's fully gone
}
