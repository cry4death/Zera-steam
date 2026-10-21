shader_type canvas_item;
uniform float alive : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	float beat = max(0.0, sin(TIME * 3.8 - UV.x * 4.0 - UV.y * 3.0));
	float square = beat * beat;
	float pulse = square * square * beat;
	COLOR.rgb *= 0.94 + pulse * 0.10 * alive;
}
