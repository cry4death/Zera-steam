shader_type canvas_item;

// Живые зомби из атласа 16×84 кадров по 48px: столбец — биты ран,
// строка — вид × 4 + кадр ходьбы.
// INSTANCE_CUSTOM: r — вспышка попадания (+2 заморожен, +4 горит, +8 элитка), g — кадр (биты ран + строка × 16),
// b — локальная кровь + «решето», a — влажность + зерно (треть диапазона задаёт ткань).
// Важно: во fragment() входной COLOR уже умножен на texture(TEXTURE, UV) — то есть
// на весь атлас целиком, поэтому его не используем. Цвет экземпляров тоже не нужен:
// лёгкая вариация оттенка считается из зерна.
uniform float rows = 84.0;
uniform sampler2D military_atlas : filter_nearest;
varying float v_military;
uniform bool remains_mode = false;
uniform bool debris_mode = false;
uniform bool surface_mode = false;
uniform vec4 surface_stain = vec4(0.5, 0.5, 0.0, 0.0);
varying vec4 v_tint;
varying float v_stain;
varying float v_wet;
varying float v_elite;
varying float v_flash;
varying float v_frame;
varying float v_holes;
varying float v_seed;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

varying float v_frozen;
varying float v_burning;
varying float v_char;
varying float v_shock;

void vertex() {
	v_tint = COLOR;
	float r = INSTANCE_CUSTOM.r;
	v_military = step(128.0, r);
	r -= v_military * 128.0;
	v_shock = step(64.0, r);
	r -= v_shock * 64.0;
	v_char = floor(r / 16.0) / 3.0;
	r = mod(r, 16.0);
	v_elite = step(8.0, r);
	r -= v_elite * 8.0;
	v_burning = step(4.0, r);
	r -= v_burning * 4.0;
	v_frozen = step(2.0, r);
	v_flash = r - v_frozen * 2.0;
	v_frame = INSTANCE_CUSTOM.g;
	v_holes = fract(INSTANCE_CUSTOM.b);
	v_stain = floor(INSTANCE_CUSTOM.b);
	v_seed = fract(INSTANCE_CUSTOM.a);
	v_wet = floor(INSTANCE_CUSTOM.a) / 6.0;
}

// Пятно и короткий потёк внутри альфы исходного спрайта; ткань вокруг сохраняется.
vec3 stain(vec3 col, vec2 uv, vec2 at, float amount, float wet) {
	vec2 p = (uv - at) * vec2(1.0, 1.3);
	float grain = hash(floor(uv * 48.0));
	float blot = 1.0 - smoothstep(0.08, 0.13 + amount * 0.09, length(p) + grain * 0.045);
	float drip = (1.0 - smoothstep(0.018, 0.045, abs(p.x + 0.035))) * step(0.0, p.y) * (1.0 - smoothstep(0.10, 0.27, p.y));
	float mask = max(blot, drip * 0.6) * min(amount, 0.86);
	vec3 ink = mix(vec3(0.024, 0.006, 0.004), vec3(0.156, 0.003, 0.0044), wet);
	ink *= mix(0.55, 1.0, grain);
	ink += vec3(0.08, 0.035, 0.04) * wet * step(0.94, grain);
	return mix(col, ink, mask);
}

void fragment() {
	if (remains_mode || debris_mode || surface_mode) {
		vec4 dead = COLOR;
		float code = floor((v_tint.r - 2.0) * 2048.0 + 0.5);
		if (v_tint.r >= 2.0 && !surface_mode) {
			dead = texture(TEXTURE, UV) * vec4(vec3(v_tint.b), v_tint.a);
		}
		if (remains_mode) {
			float grey = dot(dead.rgb, vec3(0.299, 0.587, 0.114));
			dead.rgb = mix(vec3(grey), dead.rgb, 0.16);
		}
		if (v_tint.r >= 2.0 && !surface_mode) {
			vec2 at = vec2(mod(code, 16.0), mod(floor(code / 16.0), 16.0)) / 15.0;
			dead.rgb = stain(dead.rgb, UV, at, floor(code / 256.0) / 7.0, v_tint.g);
		}
		if (surface_mode && surface_stain.z > 0.0) {
			// Погоны и полоса рюкзака героя остаются светлыми.
			float cloth = step(0.58, min(dead.r, min(dead.g, dead.b)));
			dead.rgb = mix(stain(dead.rgb, UV, surface_stain.xy, surface_stain.z, surface_stain.w), dead.rgb, cloth);
		}
		COLOR = dead;
	} else {
	float f = round(v_frame);
	float row = floor(f / 16.0);
	float bits = f - row * 16.0;
	vec2 uv = vec2((bits + UV.x) / 16.0, (row + UV.y) / rows);
	vec4 c = texture(TEXTURE, uv);
	if (v_military > 0.5) {
		c = texture(military_atlas, vec2((mod(f, 64.0) + UV.x) / 64.0, (floor(f / 64.0) + UV.y) / 48.0));
	}
	// Альфа 254 — ткань, 255 — кожа/кровь. Цвет кожи не зависит от зерна.
	if (c.a > 0.99 && c.a < 0.999) {
		float tone = floor(v_seed * 3.0);
		vec3 cloth = tone < 1.0 ? vec3(1.0) : (tone < 2.0 ? vec3(1.015, 0.94, 0.845) : vec3(0.915, 1.02, 1.10));
		c.rgb *= cloth;
		c.a = 1.0;
	}
	if (v_stain > 0.0 && c.a > 0.0) {
		vec2 at = vec2(mod(v_stain, 16.0), mod(floor(v_stain / 16.0), 16.0)) / 15.0;
		c.rgb = stain(c.rgb, UV, at, min(0.62, floor(v_stain / 256.0) / 7.0), v_wet);
	}
	// решето: кровавые дыры в пиксельной сетке спрайта
	vec2 px = floor(UV * 48.0);
	// Несколько слипшихся ран с короткими потёками; ткань между ними сохраняется.
	if (c.a > 0.0 && v_holes > 0.0) {
		vec2 wound_cell = floor((px + vec2(v_seed * 31.0, v_seed * 17.0)) / vec2(5.0, 7.0));
		vec2 wound_uv = mod(px + vec2(v_seed * 31.0, v_seed * 17.0), vec2(5.0, 7.0));
		float wound_seed = hash(wound_cell + floor(v_seed * 83.0));
		float cut = step(wound_seed, v_holes * 0.75) * step(wound_uv.x, 2.5) * step(wound_uv.y, 4.5);
		float drip = step(wound_seed, v_holes * 0.60) * step(abs(wound_uv.x - 1.0), 0.65);
		c.rgb = mix(c.rgb, vec3(0.29, 0.035, 0.025), max(cut * 0.82, drip * 0.7));
	}
	if (c.a > 0.0 && hash(px + v_seed * 97.0) < v_holes * 0.13) {
		c.rgb = hash(px * 1.7 + v_seed) < 0.5 ? vec3(0.36, 0.03, 0.03) : vec3(0.18, 0.01, 0.01);
	}
	// статусы: лёд — голубая корка с бликами, огонь — мерцающий оранжевый отсвет
	if (v_frozen > 0.5) {
		float ice = 0.55 + 0.45 * hash(px + vec2(3.0, 7.0));
		c.rgb = mix(c.rgb, vec3(0.62, 0.86, 1.0) * ice + 0.12, 0.65);
	}
	if (c.a > 0.0 && v_burning > 0.5) {
		float fl = 0.5 + 0.5 * sin(TIME * 30.0 + v_seed * 40.0 + px.y * 0.7);
		c.rgb *= 0.70 + fl * 0.15;
		c.rgb += vec3(0.12, 0.035, 0.002) * fl;
	}
	if (c.a > 0.0 && v_char > 0.0) {
		// Сначала обгорают отдельные участки ткани, затем остаётся угольная корка.
		float grain = hash(floor(px / 2.0) + v_seed * 47.0);
		float charred = smoothstep(grain * 0.6, grain * 0.6 + 0.35, v_char);
		vec3 coal = c.rgb * 0.12 + vec3(0.028, 0.024, 0.020) * (0.6 + grain * 0.4);
		c.rgb = mix(c.rgb, coal, charred * 0.93);
		if (v_burning > 0.5) c.rgb += vec3(0.22, 0.035, 0.002) * step(0.95, grain) * charred;
	}
	if (v_shock > 0.5) c.rgb = mix(c.rgb, vec3(0.69, 0.72, 0.67), step(0.2, sin(TIME * 95.0)) * 0.55);
	// У элиты тяжёлый тёмный край, без пульса и свечения.
	if (v_elite > 0.5 && c.a < 1.0) {
		vec2 cell = vec2(1.0 / 16.0, 1.0 / rows);
		vec2 lo = vec2(bits, row) * cell + TEXTURE_PIXEL_SIZE * 0.5;
		vec2 hi = lo + cell - TEXTURE_PIXEL_SIZE;
		vec2 d = TEXTURE_PIXEL_SIZE * 2.0;
		float edge = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				edge = max(edge, texture(TEXTURE, clamp(uv + vec2(float(x), float(y)) * d, lo, hi)).a);
			}
		}
		c.rgb = mix(vec3(0.045, 0.025, 0.022), c.rgb, c.a);
		c.a = max(c.a, edge * (1.0 - c.a));
	}
	// Тонкий контактный край в пределах ячейки, без светящегося ореола.
	if (c.a < 1.0 && v_elite < 0.5) {
		vec2 cell = vec2(1.0 / 16.0, 1.0 / rows);
		vec2 lo = vec2(bits, row) * cell + TEXTURE_PIXEL_SIZE * 0.5;
		vec2 hi = lo + cell - TEXTURE_PIXEL_SIZE;
		float edge = max(texture(TEXTURE, clamp(uv + vec2(TEXTURE_PIXEL_SIZE.x, 0.0), lo, hi)).a,
			texture(TEXTURE, clamp(uv + vec2(0.0, TEXTURE_PIXEL_SIZE.y), lo, hi)).a);
		c.rgb = mix(vec3(0.035, 0.028, 0.025), c.rgb, c.a);
		c.a = max(c.a, edge * 0.75);
	}
	// Даже одновременный залп оставляет светлую плоть и одежду читаемыми.
	COLOR = vec4(mix(c.rgb, vec3(0.46, 0.075, 0.06), v_flash * 0.38), c.a);
	}
}
