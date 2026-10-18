class_name HudRounds
## Настоящие патроны вместо полосы магазина (U3): спрайты по типу ствола, пакетная отрисовка без нод.
## Листы art/hud_round_<вид>.png делает tools/gen_art_hud_ammo.py: на каждый размер (ярус) слева тело патрона,
## справа маска наконечника, которая красится цветом типа патронов. Ярус выбирается по ёмкости магазина
## и свободному месту: на 6 дробин — крупная гильза, на 71 патрон ППШ — тонкая чёрточка.
## Рисует в текущих единицах канваса (HUD уже масштабирует их целым множителем).

enum Kind { RIFLE, PISTOL, SHELL, REVOLVER, SNIPER, RAIL, GRENADE }
## Как патроны попадают в ствол при перезарядке.
enum Load { PACK, SHELLS, REVOLVER, GRENADES }

const NAMES := ["rifle", "pistol", "shell", "revolver", "sniper", "rail", "grenade"]
## Ярусы по видам: [ширина, высота, шаг по x, шаг по y]; порядок и размеры совпадают с ROUNDS в gen_art_hud_ammo.py.
const TIERS := [
	[[3, 9, 4, 10], [3, 7, 4, 8], [2, 6, 3, 7], [1, 4, 2, 5]],
	[[5, 12, 6, 13], [3, 6, 4, 7], [2, 5, 3, 6], [1, 4, 2, 5], [1, 3, 2, 4]],
	[[6, 16, 8, 17], [4, 9, 5, 10], [3, 7, 4, 8], [2, 5, 3, 6]],
	[[5, 12, 6, 13], [4, 8, 5, 9], [3, 6, 4, 7]],
	[[4, 17, 5, 18], [3, 12, 4, 13], [2, 8, 3, 9]],
	[[6, 18, 8, 19], [4, 10, 5, 11], [3, 8, 4, 9]],
	[[6, 16, 8, 17], [4, 9, 5, 10], [3, 7, 4, 8]],
]
const BASE_KIND := {
	WeaponDefs.Base.RIFLE: Kind.RIFLE, WeaponDefs.Base.SMG: Kind.PISTOL, WeaponDefs.Base.PISTOL: Kind.PISTOL,
	WeaponDefs.Base.SHOTGUN: Kind.SHELL, WeaponDefs.Base.REVOLVER: Kind.REVOLVER, WeaponDefs.Base.SNIPER: Kind.SNIPER,
	WeaponDefs.Base.RAIL: Kind.RAIL, WeaponDefs.Base.LAUNCHER: Kind.GRENADE,
}
const BASE_LOAD := {
	WeaponDefs.Base.RIFLE: Load.PACK, WeaponDefs.Base.SMG: Load.PACK, WeaponDefs.Base.PISTOL: Load.PACK,
	WeaponDefs.Base.SNIPER: Load.PACK, WeaponDefs.Base.RAIL: Load.PACK,
	WeaponDefs.Base.SHOTGUN: Load.SHELLS, WeaponDefs.Base.REVOLVER: Load.REVOLVER, WeaponDefs.Base.LAUNCHER: Load.GRENADES,
}
## Цвет наконечника: у обычных патронов свой для каждого вида, дальше — по типу патронов (WeaponDefs.Ammo).
const TIP_STANDARD := [
	Color(0.80, 0.46, 0.26), Color(0.80, 0.46, 0.26), Color(0.92, 0.78, 0.42), Color(0.80, 0.46, 0.26),
	Color(0.80, 0.46, 0.26), Color(0.90, 0.96, 1.0), Color(0.62, 0.70, 0.36),
]
const TIP_AMMO := [Color.WHITE, Color(1.0, 0.88, 0.32), Color(1.0, 0.38, 0.10), Color(0.45, 0.90, 1.0)]
const RARE_TINT := Color(0.45, 0.72, 1.0)
const LOW_BODY := Color(1.0, 0.55, 0.5)
const LOW_TIP := Color(1.0, 0.27, 0.2)
const GHOST := Color(0.30, 0.31, 0.34, 0.55)
const PLATE := Color(0.0, 0.0, 0.0, 0.32)
const SLIDE := 4.0 # на сколько единиц патрон «довщёлкивается» снизу
const PACK_AT := 0.7 # магазин вставляется на 70 % перезарядки (как звук mag_in)
const PACK_SPAN := 0.2

static var _atlas: Array[Texture2D] = []


static func atlas(kind: int) -> Texture2D:
	if _atlas.is_empty():
		for n: String in NAMES:
			_atlas.append(PixelArt.tex("hud_round_" + n))
	return _atlas[kind]


static func kind_of(base: int) -> int:
	return BASE_KIND[base]


static func tip_color(kind: int, ammo: int, rare: bool) -> Color:
	var c: Color = TIP_STANDARD[kind] if ammo == 0 else TIP_AMMO[ammo]
	return c.lerp(RARE_TINT, 0.5) if rare else c


## Раскладка магазина в области w×h: ярус, число колонок и строк, смещения. Считается один раз на состав магазина.
static func layout(kind: int, mag: int, w: float, h: float) -> Dictionary:
	var tiers: Array = TIERS[kind]
	var pick := tiers.size() - 1
	var cols := 1
	var rows := 1
	for t in tiers.size():
		var td: Array = tiers[t]
		cols = maxi(1, int((w - td[0]) / td[2]) + 1)
		rows = maxi(1, int((h - td[1]) / td[3]) + 1)
		if cols * rows >= mag:
			pick = t
			break
	var d: Array = tiers[pick]
	cols = maxi(1, int((w - d[0]) / d[2]) + 1)
	rows = maxi(1, ceili(float(mag) / cols))
	var pitch := Vector2(d[2], d[3])
	if rows > 1 and (rows - 1) * pitch.y + d[1] > h:
		pitch.y = maxf(float(d[1]) * 0.6, (h - d[1]) / (rows - 1)) # ряд слишком высокий: строки теснее
	var y0 := 0
	for t in pick:
		y0 += int(tiers[t][1])
	var size := Vector2(d[0], d[1])
	var span := Vector2((mini(cols, mag) - 1) * pitch.x + size.x, (rows - 1) * pitch.y + size.y)
	return {
		"kind": kind, "tier": pick, "cols": cols, "rows": rows, "size": size, "pitch": pitch, "mag": mag,
		"offset": Vector2(0.0, floorf((h - span.y) * 0.5)), "span": span,
		"body": Rect2(0, y0, size.x, size.y), "tip": Rect2(size.x, y0, size.x, size.y),
		"ghost": mag <= 40,
	}


## Левый верхний угол патрона i относительно начала области.
static func round_at(lay: Dictionary, i: int) -> Vector2:
	var cols: int = lay["cols"]
	var pitch: Vector2 = lay["pitch"]
	return (lay["offset"] as Vector2) + Vector2((i % cols) * pitch.x, (i / cols) * pitch.y)


## Ряд патронов: live — сколько вставлено (дробная часть — патрон, который прямо сейчас вщёлкивается).
## Занятые места пусты: при небольшом магазине тёмный контур патрона, при большом — тёмная планка ряда.
static func draw_row(ci: CanvasItem, lay: Dictionary, origin: Vector2, live: float, tip: Color, body_mod: Color) -> void:
	var tex := atlas(lay["kind"])
	var size: Vector2 = lay["size"]
	var body: Rect2 = lay["body"]
	var tip_rect: Rect2 = lay["tip"]
	var mag: int = lay["mag"]
	var full := mini(int(live), mag)
	var part := live - float(full)
	var cols: int = lay["cols"]
	var pitch: Vector2 = lay["pitch"]
	var base := origin + (lay["offset"] as Vector2)
	if lay["ghost"]:
		for i in range(full, mag):
			ci.draw_texture_rect_region(tex, Rect2(base + Vector2((i % cols) * pitch.x, (i / cols) * pitch.y), size), body, GHOST)
	else:
		for r in lay["rows"]:
			var n := mini(cols, mag - r * cols)
			ci.draw_rect(Rect2(base + Vector2(-1.0, r * pitch.y - 1.0), Vector2((n - 1) * pitch.x + size.x + 2.0, size.y + 2.0)), PLATE)
	for i in full:
		var at := base + Vector2((i % cols) * pitch.x, (i / cols) * pitch.y)
		ci.draw_texture_rect_region(tex, Rect2(at, size), body, body_mod)
		ci.draw_texture_rect_region(tex, Rect2(at, size), tip_rect, tip)
	if part > 0.02 and full < mag:
		var at := base + Vector2((full % cols) * pitch.x, (full / cols) * pitch.y + (1.0 - part) * SLIDE)
		ci.draw_texture_rect_region(tex, Rect2(at, size), body, Color(body_mod, body_mod.a * part))
		ci.draw_texture_rect_region(tex, Rect2(at, size), tip_rect, Color(tip, tip.a * part))


## Патрон, выщелкнутый из ряда: k = 0…1 — подлёт, кувырок и затухание. at — левый верхний угол в единицах канваса.
static func draw_popped(ci: CanvasItem, lay: Dictionary, at: Vector2, k: float, spin: float, tip: Color, body_mod: Color, unit: float) -> void:
	var tex := atlas(lay["kind"])
	var size: Vector2 = lay["size"]
	var fade := 1.0 - k * k
	var center := at + size * 0.5 + Vector2(spin * 9.0 * k, -11.0 * k + 5.0 * k * k)
	ci.draw_set_transform(center * unit, spin * 4.0 * k, Vector2(unit, unit))
	ci.draw_texture_rect_region(tex, Rect2(-size * 0.5, size), lay["body"], Color(body_mod, body_mod.a * fade))
	ci.draw_texture_rect_region(tex, Rect2(-size * 0.5, size), lay["tip"], Color(tip, tip.a * fade))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(unit, unit))


## Сколько патронов «вставлено» прямо сейчас (дробь — вщёлкивающийся). В бою — магазин, при перезарядке — по способу заряжания:
## магазинные стволы пачкой, дробовик по одному, револьвер выбрасывает остаток и заряжает барабан, гранатомёт по одной гранате.
static func visible(mag: int, mag_max: int, reloading: bool, prog: float, load_style: int, missing: int, reload_time: float) -> float:
	if not reloading:
		return float(mag)
	match load_style:
		Load.SHELLS:
			if missing <= 0:
				return float(mag)
			var x := prog * (missing + 1)
			var n := mini(int(x), missing)
			if n <= 0:
				return float(mag)
			var age := (x - floorf(x)) * reload_time / (missing + 1) if n == int(x) else 1.0
			return float(mag + n - 1) + clampf(age / 0.12, 0.0, 1.0)
		Load.REVOLVER:
			if prog < 0.15:
				return float(mag)
			if prog < 0.5:
				return 0.0
			return clampf((prog - 0.5) / 0.4, 0.0, 1.0) * mag_max
		Load.GRENADES:
			return float(mag) + clampf((prog - 0.05) / 0.85, 0.0, 1.0) * missing
	if prog < PACK_AT:
		return 0.0
	return clampf((prog - PACK_AT) / PACK_SPAN, 0.0, 1.0) * mag_max
