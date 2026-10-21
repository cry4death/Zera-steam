shader_type canvas_item;

uniform bool depositing = false;
uniform sampler2D relief : repeat_enable, filter_linear;
varying vec4 ink;
uniform vec2 relief_scale = vec2(0.0013020833);

void vertex() {
	ink = COLOR;
}

// Раскраска слоя крови. Во входной текстуре: R — толщина (0..1), G — свежесть (1 — только что,
// к нулю — высохла). Толщина задаёт цвет и прозрачность, её перепады — «рельеф» лужи:
// тёмный ободок по краю и влажный блик на свежей крови.

uniform vec3 fresh_thin : source_color = vec3(0.32, 0.025, 0.041);
uniform vec3 fresh_thick : source_color = vec3(0.18, 0.012, 0.024);
uniform vec3 dry_thin : source_color = vec3(0.20, 0.018, 0.032);
uniform vec3 dry_thick : source_color = vec3(0.10, 0.006, 0.016);
uniform vec3 light_dir = vec3(-0.5, -0.7, 0.6);

void fragment() {
	vec4 s = texture(TEXTURE, UV);
	if (depositing) {
		float basin = texture(relief, FRAGCOORD.xy * relief_scale).r;
		// Кровь огибает сухие возвышения; рельеф запекается только под реальным пятном.
		float fill = smoothstep(0.30, 0.42, basin);
		float depth = clamp(s.r * (0.58 + ink.r) * (0.35 + basin) * mix(1.0, 0.45, ink.b), 0.035, 0.98);
		float a = s.a * fill * (0.22 + ink.r * 0.65);
		// Узкая кромка сохраняет пиксельную фактуру вместо мягкого ореола.
		a *= smoothstep(0.08, 0.45, s.a);
		COLOR = vec4(depth, 1.0, ink.b, a);
	} else {
	float t = s.r;
	// Рельеф из уже прочитанной толщины: без четырёх соседних выборок на весь разлив.
	vec2 grad = vec2(dFdx(t), dFdy(t));
	if (t < 0.03) {
		discard;
	}
	float w = smoothstep(0.04, 0.75, s.g / max(s.a, 0.01));

	float th = smoothstep(0.03, 0.85, t);
	vec3 fresh = mix(fresh_thin, fresh_thick, th);
	vec3 dried = mix(dry_thin, dry_thick, th);
	vec3 col = mix(dried, fresh, w);
	// Подошва и волочение снимают толстый слой, оставляя более светлый мазок.
	col = mix(col, mix(dry_thin, fresh_thin, w) * 0.8, s.b * 0.72);

	// мениск: край лужи темнее
	float edge = clamp(length(grad) * 2.5, 0.0, 1.0);
	col *= 1.0 - edge * 0.55;

	// влажный блик: поверхность, наклонённая к свету, бликует, пока кровь свежая
	vec3 n = normalize(vec3(-grad * 7.0, 1.0));
	vec3 l = normalize(light_dir);
	vec3 h = normalize(l + vec3(0.0, 0.0, 1.0));
	float spec = pow(max(dot(n, h), 0.0), 36.0) * smoothstep(0.55, 0.9, w) * step(0.12, t);
	// Узкий бордовый блик: белая добавка прежде делала кровь розовой.
	col += vec3(0.009, 0.0005, 0.0007) * spec;

	// Сухой пигмент остаётся на полу. Пол просвечивает только у самого края.
	float a = s.a * mix(0.97, 1.0, th) * smoothstep(0.03, 0.065, t);
	COLOR = vec4(col, a);
	}
}
