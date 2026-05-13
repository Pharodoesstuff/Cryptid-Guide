shader_type canvas_item;

uniform vec2 player_position;
uniform float radius = 50.0;
uniform float strength = 0.3;

void vertex() {
    vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

    float dist = distance(world_pos, player_position);

    if (dist < radius) {
        float influence = (radius - dist) / radius;

        // push grass away from player
        float direction = sign(world_pos.x - player_position.x);

        VERTEX.x += direction * influence * strength * VERTEX.y;
    }
}