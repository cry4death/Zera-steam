shader_type canvas_item;
render_mode unshaded;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float fx_time = 0.0;
varying float phase;
varying float opacity;
void vertex() {
	float part = floor(UV.x * 0.5);
	UV.x -= part * 2.0;
	VERTEX = (UV - 0.5) * 24.0;
	phase = INSTANCE_CUSTOM.r;
	opacity = mix(1.15, 0.68, smoothstep(0.08, 1.0, fract(INSTANCE_CUSTOM.a) * 4.0));
	VERTEX *= vec2(1.6, 1.4);
	VERTEX += vec2(6.0, -12.0);
	VERTEX *= step(0.5, mod(INSTANCE_CUSTOM.a, 2.0)) * (1.0 - step(0.5, part));
}
void fragment() {
	float t = fx_time * (0.13 + phase * 0.04);
	vec2 uv = (floor(UV * vec2(48.0, 64.0)) + 0.5) / vec2(48.0, 64.0);
	float n = texture(noise_tex, uv * vec2(0.43, 0.48) + vec2(phase * 7.0 - t * 0.3, t)).r;
	float rise = 1.0 - UV.y;
	float center = 0.42 + rise * 0.22 + (n - 0.5) * 0.38;
	float width = 0.10 + rise * 0.29;
	float mask = 1.0 - smoothstep(width * 0.25, width, abs(UV.x - center));
	mask *= smoothstep(0.0, 0.22, UV.y) * smoothstep(0.0, 0.30, rise);
	mask *= smoothstep(0.18, 0.62, n);
	vec3 col = mix(vec3(0.065, 0.061, 0.055), vec3(0.17, 0.155, 0.13), n);
	COLOR = vec4(col, mask * opacity * 0.72);
}
