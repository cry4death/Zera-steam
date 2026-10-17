shader_type canvas_item;

// Раскраска слоя крови. Во входной текстуре: R — толщина (0..1), G — свежесть (1 — только что,
// к нулю — высохла). Толщина задаёт цвет и прозрачность, её перепады — «рельеф» лужи:
// тёмный ободок по краю и влажный блик на свежей крови.

uniform vec3 fresh_thin : source_color = vec3(0.52, 0.04, 0.05);
uniform vec3 fresh_thick : source_color = vec3(0.2, 0.0, 0.015);
uniform vec3 dry_thin : source_color = vec3(0.3, 0.1, 0.07);
uniform vec3 dry_thick : source_color = vec3(0.12, 0.035, 0.025);
uniform vec3 light_dir = vec3(-0.5, -0.7, 0.6);

void fragment() {
	vec4 s = texture(TEXTURE, UV);
	float t = s.r;
	if (t < 0.03) {
		discard;
	}
	float w = clamp(s.g, 0.0, 1.0);
	vec2 px = TEXTURE_PIXEL_SIZE;
	float tl = texture(TEXTURE, UV - vec2(px.x, 0.0)).r;
	float tr = texture(TEXTURE, UV + vec2(px.x, 0.0)).r;
	float tu = texture(TEXTURE, UV - vec2(0.0, px.y)).r;
	float td = texture(TEXTURE, UV + vec2(0.0, px.y)).r;
	vec2 grad = vec2(tr - tl, td - tu);

	float th = smoothstep(0.03, 0.85, t);
	vec3 fresh = mix(fresh_thin, fresh_thick, th);
	vec3 dried = mix(dry_thin, dry_thick, th);
	vec3 col = mix(dried, fresh, w);

	// мениск: край лужи темнее
	float edge = clamp(length(grad) * 2.5, 0.0, 1.0);
	col *= 1.0 - edge * 0.4;

	// влажный блик: поверхность, наклонённая к свету, бликует, пока кровь свежая
	vec3 n = normalize(vec3(-grad * 7.0, 1.0));
	vec3 l = normalize(light_dir);
	vec3 h = normalize(l + vec3(0.0, 0.0, 1.0));
	float spec = pow(max(dot(n, h), 0.0), 36.0) * w * step(0.12, t);
	col += vec3(0.95, 0.62, 0.62) * spec * 0.55;

	float a = mix(0.5, 0.96, th) * mix(0.82, 1.0, w);
	COLOR = vec4(col, a);
}
