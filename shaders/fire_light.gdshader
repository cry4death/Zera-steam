shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float fx_time = 0.0;
varying float phase;
varying float opacity;
varying float flicker;
void vertex() {
	float part = floor(UV.x * 0.5);
	UV.x -= part * 2.0;
	VERTEX = (UV - 0.5) * 24.0;
	phase = INSTANCE_CUSTOM.r;
	opacity = pow(min(1.5, fract(INSTANCE_CUSTOM.a) * 4.0), 1.5) * INSTANCE_CUSTOM.g;
	flicker = 0.85 + 0.1 * sin(fx_time * 19.0 + phase * 73.0) + 0.05 * sin(fx_time * 31.0 + phase * 41.0);
	VERTEX *= vec2(1.5, 0.55);
	VERTEX.y += 6.0;
	VERTEX *= step(0.5, mod(INSTANCE_CUSTOM.a, 2.0)) * (1.0 - step(0.5, part));
}
void fragment() {
	float d = length((UV - 0.5) * 2.0);
	float falloff = max(0.0, 1.0 - d);
	falloff *= falloff;
	COLOR = vec4(vec3(0.95, 0.29, 0.035), falloff * opacity * flicker * 0.20);
}
