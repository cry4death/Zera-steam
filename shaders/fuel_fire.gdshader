shader_type canvas_item;
render_mode unshaded;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float fx_time = 0.0;
uniform bool jet = false;
void fragment() {
	vec2 grid = jet ? vec2(128.0, 48.0) : vec2(26.0, 18.0);
	vec2 p = (floor(UV * grid) + 0.5) / grid;
	float t = fx_time + COLOR.r * 13.0;
	float n = texture(noise_tex, p * vec2(0.9, 0.55) + vec2(-t * 0.65, t * 0.12)).r;
	float fine = texture(noise_tex, p * vec2(2.4, 1.8) + vec2(-t * 1.3, t * 0.25)).r;
	float heat;
	float smoke;
	float pool = 0.0;
	if (jet) {
		float center = 0.5 + sin(p.x * 13.0 - t * 11.0) * p.x * 0.09 + (n - 0.5) * p.x * 0.32;
		float width = 0.022 + p.x * (0.31 + n * 0.12);
		heat = 1.0 - abs(p.y - center) / width;
		heat *= 1.0 - smoothstep(0.65 + n * 0.2, 1.0, p.x);
		heat *= 0.65 + n * 0.45 + fine * 0.35;
		heat += (1.0 - smoothstep(0.01, 0.04, abs(p.y - 0.5))) * (1.0 - smoothstep(0.02, 0.22, p.x)) * 0.6;
		smoke = (1.0 - smoothstep(width, width * 1.6, abs(p.y - center))) * smoothstep(0.15, 0.6, p.x) * n;
	} else {
		pool = 1.0 - smoothstep(0.31, 0.49, length((p - vec2(0.5, 0.83)) * vec2(1.0, 3.8)) + (n - 0.5) * 0.14);
		// Низкие языки над растекающимся топливом, без центрального костра.
		float base = 0.83 + sin(p.x * 17.0) * 0.025;
		float height = 0.14 + n * 0.45;
		float u = (base - p.y) / height;
		float strand = 0.5 + 0.5 * sin(p.x * 29.0 + n * 7.0 - t * 5.0);
		heat = (1.0 - u) * strand * (0.5 + fine) * smoothstep(-0.15, 0.05, u);
		heat *= smoothstep(0.0, 0.16, p.x) * (1.0 - smoothstep(0.83, 1.0, p.x));
		smoke = (1.0 - smoothstep(0.2, 0.5, abs(p.x - 0.5))) * smoothstep(0.0, 0.2, p.y) * (1.0 - p.y) * n * 0.5;
	}
	float flame = smoothstep(0.08, 0.28, heat);
	vec3 col = mix(vec3(0.55, 0.08, 0.01), vec3(1.0, 0.38, 0.035), smoothstep(0.12, 0.5, heat));
	col = mix(col, vec3(1.0, 0.85, 0.40), smoothstep(0.57, 1.0, heat));
	vec4 tint = COLOR;
	COLOR = vec4(mix(vec3(0.09, 0.077, 0.062), col, flame), max(max(flame * 0.96, smoke * 0.55), pool * 0.75) * tint.a);
}
