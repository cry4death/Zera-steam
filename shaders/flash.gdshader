shader_type canvas_item;

// Живые зомби из атласа 16×28 кадров по 48px: столбец — биты ран,
// строка — вид × 4 + кадр ходьбы.
// INSTANCE_CUSTOM: r — вспышка попадания (+2 заморожен, +4 горит, +8 элитка), g — кадр (биты ран + строка × 16),
// b — «решето» (0..1, сколько дыр), a — зерно зомби для узора дыр.
// Важно: во fragment() входной COLOR уже умножен на texture(TEXTURE, UV) — то есть
// на весь атлас целиком, поэтому его не используем. Цвет экземпляров тоже не нужен:
// лёгкая вариация оттенка считается из зерна.
uniform float rows = 28.0;
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

void vertex() {
	float r = INSTANCE_CUSTOM.r;
	v_elite = step(8.0, r);
	r -= v_elite * 8.0;
	v_burning = step(4.0, r);
	r -= v_burning * 4.0;
	v_frozen = step(2.0, r);
	v_flash = r - v_frozen * 2.0;
	v_frame = INSTANCE_CUSTOM.g;
	v_holes = INSTANCE_CUSTOM.b;
	v_seed = INSTANCE_CUSTOM.a;
}

void fragment() {
	float f = round(v_frame);
	float row = floor(f / 16.0);
	float bits = f - row * 16.0;
	vec2 uv = vec2((bits + UV.x) / 16.0, (row + UV.y) / rows);
	vec4 c = texture(TEXTURE, uv);
	float shade = mix(0.88, 1.08, hash(vec2(v_seed * 13.0, 3.1)));
	c.rgb *= shade * vec3(mix(0.94, 1.04, hash(vec2(v_seed, 7.7))), 1.0, mix(0.92, 1.0, hash(vec2(v_seed, 1.3))));
	// решето: кровавые дыры в пиксельной сетке спрайта
	vec2 px = floor(UV * 48.0);
	if (c.a > 0.0 && hash(px + v_seed * 97.0) < v_holes * 0.13) {
		c.rgb = hash(px * 1.7 + v_seed) < 0.5 ? vec3(0.36, 0.03, 0.03) : vec3(0.18, 0.01, 0.01);
	}
	// статусы: лёд — голубая корка с бликами, огонь — мерцающий оранжевый отсвет
	if (v_frozen > 0.5) {
		float ice = 0.55 + 0.45 * hash(px + vec2(3.0, 7.0));
		c.rgb = mix(c.rgb, vec3(0.62, 0.86, 1.0) * ice + 0.12, 0.65);
	}
	if (v_burning > 0.5) {
		float fl = 0.5 + 0.5 * sin(TIME * 30.0 + v_seed * 40.0 + px.y * 0.7);
		c.rgb = mix(c.rgb, vec3(1.0, 0.45, 0.1), 0.25 + 0.2 * fl);
	}
	// Багровая пульсирующая обводка по силуэту, только у элиток.
	if (v_elite > 0.5 && c.a < 1.0) {
		vec2 cell = vec2(1.0 / 16.0, 1.0 / rows);
		vec2 lo = vec2(bits, row) * cell + TEXTURE_PIXEL_SIZE * 0.5;
		vec2 hi = lo + cell - TEXTURE_PIXEL_SIZE;
		vec2 d = TEXTURE_PIXEL_SIZE * 3.0;
		float edge = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				edge = max(edge, texture(TEXTURE, clamp(uv + vec2(float(x), float(y)) * d, lo, hi)).a);
			}
		}
		float pulse = 0.5 + 0.5 * sin(TIME * 4.5 + v_seed * 6.28);
		float aura = edge * (1.0 - c.a) * (0.7 + 0.3 * pulse);
		vec3 crimson = mix(vec3(0.34, 0.025, 0.07), vec3(0.64, 0.08, 0.17), pulse);
		c.rgb = mix(crimson, c.rgb, c.a);
		c.a = max(c.a, aura);
	}
	COLOR = vec4(mix(c.rgb, vec3(1.0), v_flash), c.a);
}
