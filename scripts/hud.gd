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
var _danger := 0.0
var _heartbeat_phase := 0.0

@onready var game = owner # скрипт game.gd корневой сцены


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # при паузе убираем анонс из-под экрана награды


func _process(delta: float) -> void:
	var cursor_mode := Input.MOUSE_MODE_HIDDEN if combat_cursor_visible() else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != cursor_mode:
		Input.mouse_mode = cursor_mode
	if not get_tree().paused:
		var target := 0.0 if game.player.is_dead else clampf(1.0 - game.player.hp / game.player.max_hp / 0.3, 0.0, 1.0)
		_danger = lerpf(_danger, target, 1.0 - exp(-delta * 4.0))
		_heartbeat_phase = fposmod(_heartbeat_phase + delta, 1.0)
	queue_redraw()


func combat_cursor_visible() -> bool:
	return not get_tree().paused and not game.game_over and not game.player.is_dead


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		game.player._input(event) # после меню прицел сразу следует за последним устройством


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
	# Тот же мягкий край, что у тревоги; рисуем до HUD, центр остаётся прозрачным.
	if _danger > 0.001:
		var beat := pow(maxf(1.0 - absf(_heartbeat_phase - 0.1) / 0.1, 0.0), 2.0)
		beat += 0.65 * pow(maxf(1.0 - absf(_heartbeat_phase - 0.3) / 0.08, 0.0), 2.0)
		draw_texture_rect(game.alarm_overlay._vignette, Rect2(0, 0, w, h), false, Color(1, 1, 1, _danger * (0.8 + beat * 0.2)))

	# опыт — полоса во всю ширину сверху
	var need := Progression.xp_to_next(prog.level)
	draw_rect(Rect2(0, 0, w, 3), Color(0.05, 0.05, 0.05, 0.8))
	draw_rect(Rect2(0, 0, w * clampf(float(prog.xp) / need, 0.0, 1.0), 3), XP_COLOR)

	# HP, рывок, уровень
	_bar(Rect2(8, 9, 110, 7), player.hp / player.max_hp, Color(0.75, 0.1, 0.1))
	_text(font, Vector2(122, 16), "%d" % ceili(player.hp), TEXT)
	# рывок: по сегменту на заряд; адреналин — тонкая полоска под ним
	var seg := (40.0 - 3.0 * (player.dash_max - 1)) / player.dash_max
	for k in player.dash_max:
		var fill := 1.0 if k < player.dash_left else (1.0 - player.dash_cd / player.dash_cooldown if k == player.dash_left else 0.0)
		_bar(Rect2(8 + k * (seg + 3.0), 19, seg, 3), fill, Color(0.4, 0.75, 1.0) if fill >= 1.0 else Color(0.3, 0.45, 0.6))
	if player.adrenaline:
		var adr := 1.0 - player.adrenaline_cd / Meta.ADRENALINE_COOLDOWN
		_bar(Rect2(8, 25, 40, 1), adr, Color(1.0, 0.45, 0.7) if adr >= 1.0 else Color(0.5, 0.25, 0.35))
	_text(font, Vector2(8, 34), "УР. %d" % prog.level, XP_COLOR, 11)
	_text(font, Vector2(78, 34), "%d кр." % prog.credits, CREDIT_COLOR, 9)
	_draw_grenade(font, player, Vector2(52, 18))

	# время и убийства
	var t := int(game.time)
	_text_centered(font, Vector2(w * 0.5, 17), "%02d:%02d" % [t / 60, t % 60], TEXT, 12)
	_text_centered(font, Vector2(w * 0.5, 29), "убито: %d" % game.kills, DIM)
	_draw_operation(font, w)

	# стволы
	var n := weapons.slots.size()
	var total := n * PANEL_W + (n - 1) * 6.0
	var x0 := (w - total) * 0.5
	var y0 := h - 50.0
	_draw_boss_bar(font, w, y0 - 32.0)
	for i in n:
		_draw_slot(font, weapons, i, Vector2(x0 + i * (PANEL_W + 6.0), y0))
	var aim_hint := "АВТО · ПКМ — свой прицел" if Meta.settings["auto_fire"] else "РУЧНОЙ · ЛКМ — огонь"
	if player.aim_gamepad:
		aim_hint = "АВТО · правый стик — свой прицел" if Meta.settings["auto_fire"] else "РУЧНОЙ · RT — огонь"
	_text_centered(font, Vector2(w * 0.5, h - 3), aim_hint + "   ·   " + ("RB" if player.aim_gamepad else "G / СКМ") + " — граната", DIM, 8)

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
		_text_right(font, Vector2(w - 8, h - 54), "F1 +100 · F2 бессм. · F3 отладка · F4 +1 мин · F5 патроны · F6 смерть · F7 бегуны · F8 толстяк · F9 плевальщик · F10 элитка", Color(0.5, 0.5, 0.48), 7)

	# комбо и надписи
	if game.combo >= 5:
		_text_right(font, Vector2(w - 8, h * 0.5), "×%d" % game.combo, Color(0.95, 0.5, 0.4))
	if game.announce_t > 0.0 and not game.level_up.visible and game.mission_banner_t <= 0.0:
		var k: float = game.announce_t / 1.4
		var fs := int(lerpf(18.0, 26.0, clampf((k - 0.85) / 0.15, 0.0, 1.0))) # «удар» при появлении
		var col: Color = game.announce_color
		col.a = clampf(k * 2.0, 0.0, 1.0)
		var jitter := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (k * 2.0)
		# пока на экране тревога (заголовок, полоса, «ТРЕВОГА ОТБИТА»), анонсы идут ниже неё
		var ay := 112.0 if game.alarm_overlay.visible else 70.0
		_text_centered(font, Vector2(w * 0.5, ay) + jitter, game.announce_text, col, fs)
	if combat_cursor_visible():
		_draw_crosshair(player)


## Короткие штрихи с просветом и тёмной обводкой видны и на крови, и на асфальте.
func _draw_crosshair(player: Player) -> void:
	var p := player.aim_mouse_position / _ui
	if player.aim_gamepad:
		p = (player.get_canvas_transform() * player.aim_point) / _ui
	p = p.round()
	var color := Color(1.0, 0.94, 0.70) if player.manual_aim else Color(0.65, 0.67, 0.65)
	for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(p + dir * 2.0, p + dir * 4.0, Color(0.015, 0.012, 0.01, 0.95), 3.0)
		draw_line(p + dir * 2.0, p + dir * 4.0, color, 1.0)



## Короткая радиосводка и постоянная строка. Значки читаются без цвета.
func _draw_operation(font: Font, w: float) -> void:
	if game.mission_config.is_empty() or game.game_over:
		return
	var color := Color(0.65, 0.82, 0.83)
	_text_centered(font, Vector2(w * 0.5, 42), "ОП: " + game.mission_title, color, 9)
	var count: int = game.mission_modifiers.size()
	for i in count:
		var p := Vector2(w * 0.5 + (i - (count - 1) * 0.5) * 19.0, 52)
		draw_rect(Rect2(p - Vector2(7, 6), Vector2(14, 12)), Color(0.035, 0.065, 0.07, 0.9))
		var id: String = game.mission_modifiers[i]
		match id:
			"runner_surge":
				for dx in [-3.0, 1.0]:
					draw_polyline(PackedVector2Array([p + Vector2(dx - 2, -3), p + Vector2(dx + 1, 0), p + Vector2(dx - 2, 3)]), color, 1.0)
			"elite_hunt":
				draw_polyline(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0), p + Vector2(0, -4)]), color, 1.0)
			"acid_rain":
				draw_polyline(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3, 2), p + Vector2(0, 4), p + Vector2(-3, 2), p + Vector2(0, -4)]), color, 1.0)
			"blood_frenzy":
				draw_polyline(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(-2, 0), p + Vector2(0, -4), p + Vector2(2, 4), p + Vector2(3, 0), p + Vector2(5, 0)]), color, 1.0)
			"hardened_boss":
				draw_polyline(PackedVector2Array([p + Vector2(-4, -3), p + Vector2(4, -3), p + Vector2(3, 2), p + Vector2(0, 4), p + Vector2(-3, 2), p + Vector2(-4, -3)]), color, 1.0)
			"resource_cache":
				draw_rect(Rect2(p - Vector2(4, 3), Vector2(8, 6)), color, false, 1.0)
				draw_line(p + Vector2(-4, 0), p + Vector2(4, 0), color)
	if game.mission_banner_t <= 0.0 or game.level_up.visible or game.trader_ui.visible:
		return
	var width := minf(420.0, w - 24.0)
	var x := (w - width) * 0.5
	draw_rect(Rect2(x, 70, width, 73), Color(0.018, 0.035, 0.04, 0.96))
	draw_line(Vector2(x, 70), Vector2(x + width, 70), color, 1.0)
	_text(font, Vector2(x + 12, 82), "Z.E.R.A. / ДИСПЕТЧЕР / ОПЕРАЦИЯ", color, 8)
	_text(font, Vector2(x + 12, 101), game.mission_config["name"].to_upper(), TEXT, 15)
	_text(font, Vector2(x + 12, 116), game.mission_region, color, 9)
	_text(font, Vector2(x + 12, 132), game.mission_mod_names, DIM, 9)


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
	_bar(Rect2(x, y + 4, width, 6), boss.hp / boss.max_hp, color)
	var threshold := x + width * boss.armor_threshold
	draw_line(Vector2(threshold, y + 3), Vector2(threshold, y + 11), Color(1.0, 0.85, 0.65), 1.0)
	_text_right(font, Vector2(x + width, y), "%d / %d" % [ceili(boss.hp), int(boss.max_hp)], DIM, 8)


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
	var proto := s.prototype >= 0
	draw_rect(Rect2(p, Vector2(PANEL_W, 37)), Color(0.04, 0.04, 0.04, 0.55))
	var title: String = "%s ур.%d" % [s.short_name(), s.level] if not proto else WeaponDefs.PROTOTYPES[s.prototype]["name"]
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
	if s.charged:
		_text(font, p + Vector2(PANEL_W - 38, 18), "◆ ×1.5", Color(1.0, 0.72, 0.35), 8)
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
