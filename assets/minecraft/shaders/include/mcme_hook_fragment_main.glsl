// lava: its own light, with only the game's shading of its sides. The base
// has told which fluid the face is (fluid) and where on it (fluidHere), and
// drawn its water.
if ((fluid == LAVA_STILL || fluid == LAVA_FLOWING) && fireLayer < 0) {
    color = vec4(lavaColor(fluid, fluidHere, MCME_SECONDS) * mix(vec3(1.0), vertexColor.rgb, LAVA_SHADING), 1.0);
}
// ice: seen into, lit and shaded as any block - its frost by its face's own
// shade, not the occlusion that puts it there
if ((fluid == ICE_PACKED || fluid == ICE_BLUE) && fireLayer < 0) {
    vec4 ice = iceColor(fluid, fluidHere, MCME_SECONDS, shore, MCME_FOG_COLOR.rgb);
    vec3 open = vertexColor.rgb / max(max(vertexColor.r, max(vertexColor.g, vertexColor.b)), 1.0e-3) * shore.open;
    color = vec4(ice.rgb * mix(vertexColor.rgb, open, ice.a) * lightColor.rgb, 1.0);
}
// the fire eye: its own light, no shading, no light map
if (fireLayer >= 0) {
    color = fireColor();
    // with a distant terrain mod the sky draws the eye from FIRE_HANDOVER on
    // (core/sky.fsh), where this block can no longer be: it hands over
    if (farTerrain(MCME_FOG_START)) color.a *= 1.0 - fireHandover(length(fireCentre));
    if (color.a <= 0.0) discard;              // only what's fully gone
}
