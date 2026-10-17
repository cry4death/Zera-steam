extends Control
## HUD рисуется вручную в «игровых» пикселях (по высоте ~360) и масштабируется
## целым множителем под экран: 1080p → ×3. Текст рисуется в полном разрешении.

const TEXT := Color(0.9, 0.9, 0.85)
const DIM := Color(0.6, 0.6, 0.58)
const FONT_SIZE := 10
const XP_COLOR := Color(0.35, 0.9, 0.55)
const CREDIT_COLOR := Color(1.0, 0.82, 0.35)
const PANEL_W := 118.0

var show_debug := true
var _ui := 2.0
var _grenade_icon: Texture2D

@onready var game = owner # скрипт game.gd корневой сцены


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # при паузе убираем анонс из-под экрана награды


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		show_debug = not show_debug


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var player: Player = game.player
	var weapons: Weapons = game.weapons
	var horde: Horde = game.horde
	var prog: Progression = game.progression
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var w := size.x / _ui
	var h := size.y / _ui

	# опыт — полоса во всю ширину сверху
	var need := Progression.xp_to_next(prog.level)
	draw_rect(Rect2(0, 0, w, 3), Color(0.05, 0.05, 0.05, 0.8))
	draw_rect(Rect2(0, 0, w * clampf(float(prog.xp) / need, 0.0, 1.0), 3), XP_COLOR)

	# HP, рывок, уровень
	_bar(Rect2(8, 9, 110, 7), player.hp / player.max_hp, Color(0.75, 0.1, 0.1))
	_text(font, Vector2(122, 16), "%d" % ceili(player.hp), TEXT)
	var dash_ready := 1.0 - player.dash_cd / player.dash_cooldown
	_bar(Rect2(8, 19, 40, 3), dash_ready, Color(0.4, 0.75, 1.0) if dash_ready >= 1.0 else Color(0.3, 0.45, 0.6))
	_text(font, Vector2(8, 34), "УР. %d" % prog.level, XP_COLOR, 11)
	_text(font, Vector2(78, 34), "%d кр." % prog.credits, CREDIT_COLOR, 9)
	_draw_grenade(font, player, Vector2(52, 18))

	# время и убийства
	var t := int(game.time)
	_text_centered(font, Vector2(w * 0.5, 17), "%02d:%02d" % [t / 60, t % 60], TEXT, 12)
	_text_centered(font, Vector2(w * 0.5, 29), "убито: %d" % game.kills, DIM)

	# стволы
	var n := weapons.slots.size()
	var total := n * PANEL_W + (n - 1) * 6.0
	var x0 := (w - total) * 0.5
	var y0 := h - 50.0
	_draw_boss_bar(font, w, y0 - 26.0)
	for i in n:
		_draw_slot(font, weapons, i, Vector2(x0 + i * (PANEL_W + 6.0), y0))

	# пассивки — под уровнем
	var py := 46.0
	for p in prog.passives:
		var d: Dictionary = WeaponDefs.PASSIVES[p]
		_text(font, Vector2(8, py), "%s %s" % [d["name"], WeaponDefs.ROMAN[prog.passives[p]]], Color(0.55, 0.95, 0.6, 0.8), 8)
		py += 9.0

	if show_debug:
		var lines := [
			"FPS %d" % Engine.get_frames_per_second(),
			"зомби %d" % horde.count,
			"орда %.2f мс" % horde.update_ms,
			"пули %d" % weapons.bullet_count,
			"обломки %d" % game.gore.count,
			"образцы %d" % game.gems.count,
			"кредиты на земле %d" % game.credit_drops.count,
			"смерть: %s" % ("авто" if horde.death_override < 0 else Gore.DEATH_NAMES[horde.death_override]),
			"спавн %.1f/с" % game.spawner.current_rate(),
			"бессмертие" if player.god_mode else "",
		]
		for i in lines.size():
			_text_right(font, Vector2(w - 8, 15 + i * 11), lines[i], DIM)
		_text_right(font, Vector2(w - 8, h - 4), "F1 +100 · F2 бессм. · F3 отладка · F4 +1 мин · F5 патроны · F6 смерть · F7 бегуны · F8 толстяк · F9 плевальщик · F10 элитка", Color(0.5, 0.5, 0.48), 7)

	# комбо и надписи
	if game.combo >= 5:
		_text_right(font, Vector2(w - 8, h * 0.5), "×%d" % game.combo, Color(0.95, 0.5, 0.4))
	if game.announce_t > 0.0 and not game.level_up.visible:
		var k: float = game.announce_t / 1.4
		var fs := int(lerpf(18.0, 26.0, clampf((k - 0.85) / 0.15, 0.0, 1.0))) # «удар» при появлении
		var col: Color = game.announce_color
		col.a = clampf(k * 2.0, 0.0, 1.0)
		var jitter := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (k * 2.0)
		# пока на экране тревога (заголовок, полоса, «ТРЕВОГА ОТБИТА»), анонсы идут ниже неё
		var ay := 112.0 if game.alarm_overlay.visible else 70.0
		_text_centered(font, Vector2(w * 0.5, ay) + jitter, game.announce_text, col, fs)



func _draw_boss_bar(font: Font, w: float, y: float) -> void:
	var boss: Boss = game.boss
	if not boss.is_alive():
		if game.time >= 570.0 and game.time < 600.0 and not game.game_over:
			_text_centered(font, Vector2(w * 0.5, y + 12), "ОБЪЕКТ-7 ПРИБЛИЖАЕТСЯ", Color(1.0, 0.38, 0.19, 0.7 + 0.3 * sin(game.time * 5.0)), 12)
		return
	var width := minf(360.0, w - 32.0)
	var x := (w - width) * 0.5
	var color := Color(0.75, 0.15, 0.09) if boss.phase == 1 else Color(1.0, 0.28, 0.12)
	if game.boss_phase_flash > 0.0:
		color = color.lerp(Color.WHITE, game.boss_phase_flash / 0.7)
	draw_rect(Rect2(x - 5, y - 10, width + 10, 25), Color(0.035, 0.025, 0.025, 0.9))
	_text_centered(font, Vector2(w * 0.5, y), "ОБЪЕКТ-7 · " + ("БРОНЯ" if boss.phase == 1 else "БРОНЯ СОРВАНА"), color, 10)
	_bar(Rect2(x, y + 4, width, 6), boss.hp / Boss.MAX_HP, color)
	draw_line(Vector2(w * 0.5, y + 3), Vector2(w * 0.5, y + 11), Color(1.0, 0.85, 0.65), 1.0)
	_text_right(font, Vector2(x + width, y), "%d / %d" % [ceili(boss.hp), int(Boss.MAX_HP)], DIM, 8)


## Активка «граната»: иконка, затемнение-кулдаун сверху вниз, секунды или клавиша.
func _draw_grenade(font: Font, player: Player, p: Vector2) -> void:
	if _grenade_icon == null:
		_grenade_icon = PixelArt.tex("icon_grenade")
	var cd := player.grenade_cd / Player.GRENADE_COOLDOWN
	var r := Rect2(p, _grenade_icon.get_size())
	draw_rect(r.grow(1.0), Color(0.05, 0.05, 0.05, 0.75))
	draw_texture(_grenade_icon, p, Color.WHITE if cd <= 0.0 else Color(1, 1, 1, 0.5))
	if cd > 0.0:
		draw_rect(Rect2(p, Vector2(r.size.x, r.size.y * cd)), Color(0, 0, 0, 0.6))
		_text_centered(font, p + Vector2(r.size.x * 0.5, r.size.y * 0.5 + 3.0), "%d" % ceili(player.grenade_cd), TEXT, 8)
	else:
		_text(font, p + Vector2(r.size.x + 3.0, r.size.y * 0.5 + 3.0), "G", Color(1.0, 0.8, 0.45), 8)


## Панель ствола: имя и уровень, патроны, модули, магазин или перезарядка.
func _draw_slot(font: Font, weapons: Weapons, i: int, p: Vector2) -> void:
	var s: Weapons.Slot = weapons.slots[i]
	var d: Dictionary = WeaponDefs.BASES[s.base]
	var proto := s.prototype >= 0
	draw_rect(Rect2(p, Vector2(PANEL_W, 37)), Color(0.04, 0.04, 0.04, 0.55))
	var title: String = "%s ур.%d" % [d["short"], s.level] if not proto else WeaponDefs.PROTOTYPES[s.prototype]["name"]
	_text(font, p + Vector2(4, 9), title, Color(1.0, 0.6, 0.3) if proto else TEXT, 9)
	var ammo_col: Color = [Color(0.85, 0.85, 0.8), Color(1.0, 0.85, 0.5), Color(1.0, 0.55, 0.2), Color(0.6, 0.9, 1.0)][s.ammo]
	if s.ammo_rare:
		ammo_col = ammo_col.lerp(Color(0.45, 0.72, 1.0), 0.4)
	_text(font, p + Vector2(4, 18), "%s %s" % [WeaponDefs.AMMO[s.ammo]["name"], WeaponDefs.ROMAN[s.ammo_rank]], ammo_col, 7)
	var mods: Array[String] = []
	for m in s.modules:
		var mname: String = WeaponDefs.MODULES[m["id"]]["name"]
		mods.append("%s %s" % [mname.left(5), WeaponDefs.ROMAN[m["rank"]]])
	if not mods.is_empty():
		_text(font, p + Vector2(4, 26), " · ".join(mods), Color(0.7, 0.75, 0.85), 7)
	var bar := Rect2(p + Vector2(4, 31), Vector2(PANEL_W - 8, 3))
	if s.reloading:
		_bar(bar, weapons.reload_progress(i), Color(0.9, 0.7, 0.25))
	else:
		_bar(bar, float(s.mag) / s.stats["mag"], Color(0.95, 0.8, 0.4))


func _bar(r: Rect2, fill: float, color: Color) -> void:
	draw_rect(r.grow(1.0), Color(0.05, 0.05, 0.05, 0.8))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(fill, 0.0, 1.0), r.size.y)), color)


func _text(font: Font, p: Vector2, s: String, c: Color, fs := FONT_SIZE) -> void:
	draw_set_transform(Vector2.ZERO)
	var k := int(_ui)
	draw_string_outline(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _text_centered(font: Font, p: Vector2, s: String, c: Color, fs := FONT_SIZE) -> void:
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, Vector2(p.x - tw * 0.5, p.y), s, c, fs)


func _text_right(font: Font, p: Vector2, s: String, c: Color, fs := FONT_SIZE) -> void:
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, Vector2(p.x - tw, p.y), s, c, fs)
