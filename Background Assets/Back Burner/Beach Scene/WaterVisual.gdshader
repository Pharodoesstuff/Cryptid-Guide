shader_type canvas_item;

uniform vec3 wave_color: source_color = vec3(0.1, 0.4, 0.9); // Color of the wave
uniform vec3 edge_color: source_color = vec3(1.0, 1.0, 1.0); // Color of the edge
uniform vec3 bubble_color: source_color = vec3(0.1, 0.4, 0.9); // Color of the bubbles
uniform sampler2D wave_texture : hint_default_black;         // Texture for the wave
uniform float wave_opacity: hint_range(0.0, 1.0) = 0.8;      // Opacity of the wave
uniform float edge_width: hint_range(0.0, 0.1) = 0.04;       // Thickness of the edge
uniform float texture_blend: hint_range(0.0, 1.0) = 0.5;     // Blend factor for the texture
uniform float bubble_opacity: hint_range(0.0, 1.0) = 0.5;    // Opacity of the bubbles
uniform float bubble_speed: hint_range(0.0, 1.0) = 0.1;      // Speed of bubble motion
uniform int bubble_count: hint_range(1, 50) = 0;            // Number of bubbles
uniform float speed: hint_range(0.1, 3.0) = 1.0;             // Speed of wave motion

float get_particle_x(int i) {
    return (sin(float(i)) * 0.5) * (sin(float(i) * 6.0) + 0.5) * 1.75 + 0.5;
}

void vertex() {
}

void fragment() {
    // Transparent background
    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);

    // Smooth wave animation
    float sine = sin(UV.x * 0.5 + (TIME * 0.3 * speed)) * 0.03 + 0.6;
    float sine_2 = sin(UV.x * 1.0 + (TIME * 0.6 * speed)) * 0.01;
    float sine_3 = sin(UV.x * 12.0 + (TIME * 0.9 * speed)) * 0.03;
    float wave_height = sine + sine_2 + sine_3;

    // Determine the wave and edge areas
    float edge_mask = smoothstep(wave_height - edge_width * 0.2, wave_height, UV.y);
    float wave_mask = smoothstep(wave_height, wave_height + edge_width * 0.9, UV.y);

    // Apply edge color
    col.rgb = mix(col.rgb, edge_color, edge_mask);

    // Apply wave color
    col.rgb = mix(col.rgb, wave_color, wave_mask);

    // Add alpha for non-background areas
    col.a = max(edge_mask, wave_mask) * wave_opacity;

    // Apply static texture to the wave mask
    vec2 texture_coords = vec2(UV.x, UV.y); // Static texture without TIME offset
    vec4 texture_color = texture(wave_texture, texture_coords);

    // Blend texture with the wave
    col.rgb = mix(col.rgb, texture_color.rgb, texture_blend * wave_mask);

    // BUBBLES
    for (int i = 1; i <= bubble_count; i++) {
        float particle_x = get_particle_x(i);
        float time_offset = get_particle_x(i + 2) * 40.0;
        float speed_offset = get_particle_x(i + 3) * bubble_speed;
        float scale_factor = get_particle_x(i + 5) * 0.01;

        // Generate a particle position that animates downward
        vec2 particle = vec2(particle_x, (fract((TIME + time_offset) * (-0.06 * speed_offset)) * 2.0) - 0.5);

        // Generate circles based on length from point in UV
        float circle = step(length(UV - particle), 0.04 - scale_factor);
        float inner_circle = step(length(UV - particle), (0.04 - scale_factor) - (2.0 * SCREEN_PIXEL_SIZE.y));

        // Calculate distance to wave for popping
        float bubble_wave_dist = abs(UV.y - wave_height);

        // Adjust bubble proximity to the wave edge
        float pop_threshold = 0.0005; // Reduced distance for closer popping
        float pop_factor = smoothstep(pop_threshold, 0.0, bubble_wave_dist);
        vec4 bubble_col = vec4(bubble_color, bubble_opacity * pop_factor);

        // Add popping effect to bubbles
        col.rgb = mix(col.rgb, bubble_col.rgb, circle - inner_circle * 0.7);
        col.a = max(col.a, (circle - inner_circle * 0.7) * bubble_col.a);
    }

    COLOR = col;
}
