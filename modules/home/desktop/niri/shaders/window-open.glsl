// Rise into place: the window comes up 16 px from 90% of its size while it
// fades in. Scale and offset follow the unclamped curve, and the overshoot
// is amplified to niri's own pop (its default grows from 50%), so the
// window still lands a hair past full size and settles back.
vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_progress;

    float scale = mix(0.9, 1.0, p) + max(p - 1.0, 0.0) * 0.4;
    vec2 offset = vec2(0.0, (1.0 - p) * 16.0 / size_geo.y);
    vec2 coords = (coords_geo.xy - vec2(0.5) - offset) / scale + vec2(0.5);

    // The shader area is larger than the window; outside the texture is empty
    // rather than its clamped edge.
    vec3 coords_tex = niri_geo_to_tex * vec3(coords, 1.0);
    if (coords_tex.x < 0.0 || coords_tex.x > 1.0 || coords_tex.y < 0.0 || coords_tex.y > 1.0)
        return vec4(0.0);

    vec4 color = texture2D(niri_tex, coords_tex.st);
    return color * smoothstep(0.0, 0.6, niri_clamped_progress);
}
