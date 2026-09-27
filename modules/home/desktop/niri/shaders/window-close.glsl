// Burn away: the window dissolves along a noise pattern while a thin edge in
// the stylix accent (substituted by decoration.nix) runs ahead of the hole.
// Two octaves of value noise and one texture read per pixel.

float burn_hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float burn_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(burn_hash(i), burn_hash(i + vec2(1.0, 0.0)), u.x),
        mix(burn_hash(i + vec2(0.0, 1.0)), burn_hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    vec3 coords_tex = niri_geo_to_tex * coords_geo;
    if (coords_tex.x < 0.0 || coords_tex.x > 1.0 || coords_tex.y < 0.0 || coords_tex.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, coords_tex.st);

    // Blobs about 60 logical px across with finer detail on top, so big and
    // small windows burn alike; the seed gives every close its own pattern.
    vec2 cell = coords_geo.xy * size_geo.xy / 60.0 + niri_random_seed * 97.0;
    float noise = burn_noise(cell) * 0.7 + burn_noise(cell * 4.0) * 0.3;

    // The front sweeps the whole noise range: nothing is gone at 0, all at 1.
    float edge = 0.08;
    float front = mix(-edge, 1.0, niri_clamped_progress);
    float above = noise - front;
    if (above < 0.0)
        return vec4(0.0);

    // 1 right at the front, fading to the window past the edge band.
    float glow = 1.0 - smoothstep(0.0, edge, above);
    vec4 ember = vec4(@accent@, 1.0) * color.a;
    return mix(color, ember, glow);
}
