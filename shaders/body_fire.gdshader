shader_type canvas_item;
render_mode unshaded;
uniform float fx_time = 0.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
varying float phase;
varying float intensity;
varying float opacity;
varying float part;
varying vec2 point;
varying vec2 heading;
varying vec2 anchor;
varying vec2 flow;
varying float extent;
varying float width;
varying float life;
void vertex() {
	phase = INSTANCE_CUSTOM.r;
	intensity = fract(INSTANCE_CUSTOM.a) * 4.0;
	opacity = INSTANCE_CUSTOM.g;
	part = floor(UV.x * 0.5);
	UV.x -= part * 2.0;
	heading = vec2(cos(INSTANCE_CUSTOM.b), sin(INSTANCE_CUSTOM.b));
	mat2 turn = mat2(heading, vec2(-heading.y, heading.x));
	float packed_drift = floor(INSTANCE_CUSTOM.a / 4.0);
	vec2 drift = (vec2(mod(packed_drift, 33.0), floor(packed_drift / 33.0)) - 16.0) * 0.25;
	vec2 wind = vec2(1.1 + sin(fx_time * 0.7) * 0.4, -0.65 + sin(fx_time * 0.47) * 0.45);
	flow = normalize(drift + wind);
	float t = fx_time * (0.85 + phase * 0.3);
	float s = fract(phase * 17.13 + part * 0.3819);
	float vigor = smoothstep(0.08, 1.0, intensity);
	float spread = (0.65 + vigor * 0.35) * (1.0 + max(0.0, intensity - 1.0) * 0.5);
	anchor = vec2(0.0);
	extent = 1.0;
	width = 1.0;
	life = 1.0;
	if (part < 0.5) {
		point = turn * (vec2(-3.5, 0.0) + (UV - 0.5) * vec2(19.0, 23.0) * spread);
	} else if (part < 2.5 && mod(floor(INSTANCE_CUSTOM.a / 2.0), 2.0) < 0.5) {
		anchor = turn * vec2(-3.0 + s * 3.0, (part - 1.5) * 11.0);
		extent = (3.5 + s * 4.5 + length(drift) * 1.6 + sin(t * 8.0 + s * 19.0) * 1.6) * spread;
		width = (2.4 + s * 1.5) * spread;
		vec2 side = vec2(-flow.y, flow.x);
		point = anchor + flow * (UV.y * extent - 1.0) + side * (UV.x * 2.0 - 1.0) * (width + 2.0);
		life = vigor;
	} else if (part > 2.5 && part < 3.5 && mod(floor(INSTANCE_CUSTOM.a / 2.0), 2.0) < 0.5) {
		// Один оторвавшийся клочок: 0,2 с жизни, отдельная фаза каждого тела.
		float age = fract(fx_time * 5.0 + phase * 37.0);
		anchor = turn * vec2(-4.0, sin(phase * 71.0) * 6.0) + flow * (5.0 + age * (5.0 + length(drift)));
		width = (1.0 - age) * 2.4;
		point = floor(anchor) + (UV - 0.5) * 6.0;
		life = sin(age * 3.14159) * vigor;
	} else if (part > 3.5) {
		float age = fract(fx_time / 0.3 + phase * 11.0);
		point = floor(turn * vec2(-3.0, sin(phase * 57.0) * 7.0) + flow * (3.0 + age * 11.0)) + UV - 0.5;
		life = sin(age * 3.14159) * min(1.0, intensity * 2.0);
	} else {
		point = vec2(0.0);
		life = 0.0;
	}
	// Компенсация общего трансформа буфера W7c; точки остаются на теле.
	VERTEX = vec2(point.x * 0.75, (point.y + 12.0) * 0.5);
}
void fragment() {
	if (part > 3.5) {
		COLOR = vec4(1.0, 0.38, 0.035, life * opacity);
	} else {
		vec2 p = floor(point) + 0.5;
		float t = fx_time * (0.85 + phase * 0.3);
		vec2 uv = p * 0.045 + vec2(phase * 13.0 - t * 0.25, t * 0.34);
		float n = texture(noise_tex, uv).r;
		float fine = texture(noise_tex, uv * 2.1 + vec2(t * 0.19, -t * 0.13)).r;
		float vigor = smoothstep(0.08, 1.0, intensity);
		float heat = 0.0;
		if (part < 0.5) {
			vec2 local = vec2(dot(p, heading), dot(p, vec2(-heading.y, heading.x)));
			float spread = (0.65 + vigor * 0.35) * (1.0 + max(0.0, intensity - 1.0) * 0.5);
			local = (local - vec2(-3.5, 0.0)) / spread;
			// Спина и два плеча: пустоты между очагами сохраняют силуэт и руки.
			float asym = fract(phase * 21.73);
			float body = min(length(local / vec2(5.0 + asym * 1.5, 4.5 + asym)), length((local - vec2(asym - 0.5, sign(local.y) * (4.0 + asym))) / vec2(3.6 + asym, 3.2 + asym * 0.6)));
			float edge = 1.0 - body + (n - 0.5) * 0.9 + (fine - 0.5) * 0.45;
			heat = max(0.0, edge) * (0.55 + fine * 0.9);
			heat *= smoothstep(0.15, 0.43, fine + vigor * 0.2);
		} else if (part < 2.5) {
			vec2 offset = p - anchor;
			float u = dot(offset, flow) / extent;
			float bend = sin(u * 5.0 + t * 9.0 + phase * 27.0) * 1.3 + (n - 0.5) * 3.0;
			float cross_flow = dot(offset, vec2(-flow.y, flow.x)) - bend * u;
			float rim = width * (1.0 - u) * (0.6 + n);
			heat = max(0.0, 1.0 - abs(cross_flow) / max(0.3, rim));
			heat *= smoothstep(-0.12, 0.12, u) * (1.0 - smoothstep(0.6, 1.0, u)) * (0.5 + fine * 0.6);
		} else {
			heat = max(0.0, 1.0 - length(p - anchor) / max(0.1, width)) * (0.5 + fine * 0.6);
		}
		float coal = smoothstep(0.47, 0.70, fine) * (1.0 - vigor);
		float alpha = smoothstep(0.08, 0.30, heat) * life * mix(coal, 0.94, vigor);
		vec3 col = mix(vec3(0.40, 0.035, 0.003), vec3(0.98, 0.23, 0.009), smoothstep(0.12, 0.47, heat) * vigor);
		col = mix(col, vec3(1.0, 0.79, 0.28), smoothstep(0.48, 0.95, heat) * vigor);
		COLOR = vec4(col, alpha * opacity);
	}
}
