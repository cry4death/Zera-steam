class_name HordeAudio
extends Node
## Один проход по packed-массивам раз в 0.15 с; отдельных нод на зомби нет.

const HEARING := 600.0
var horde: Horde
var player: Player
var sfx: Sfx
var mix := 0.0
var density := 0.0
var _timer := 0.0
var _attack_cd := 0.0
var _center := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(source: Horde, target: Player, audio: Sfx) -> void:
	horde = source
	player = target
	sfx = audio
	_center = player.position
	_rng.randomize()
	horde.enemy_hit.connect(sfx.queue_hit)
	horde.enemy_killed.connect(_death)
	horde.fat_burst.connect(_fat)
	horde.spit_fired.connect(_spit)
	set_process(DisplayServer.get_name() != "headless" and not sfx._silent)


func _process(delta: float) -> void:
	if player.is_dead:
		sfx.ambience(player.position, 0.0, 0.0, delta)
		return
	_timer -= delta
	_attack_cd -= delta
	if _timer <= 0.0:
		_timer = 0.15
		_sample()
	sfx.ambience(_center, density, mix, delta)


func _sample() -> void:
	var total := 0.0
	var center := Vector2.ZERO
	var nearby := 0
	var choices := PackedInt32Array([-1, -1])
	var weight := 0.0
	var touching := -1
	for i in horde.count:
		if horde.dead[i] != 0:
			continue
		var d := player.position.distance_squared_to(horde.pos[i])
		if d > HEARING * HEARING:
			continue
		nearby += 1
		var w := 1.0 - sqrt(d) / HEARING
		center += horde.pos[i] * w
		total += w
		# Два независимых взвешенных резервуара: ближние попадают чаще.
		weight += w
		for k in 2:
			if _rng.randf() * weight < w:
				choices[k] = i
		if d < pow(Player.RADIUS + horde.radius[i] + 3.0, 2.0):
			touching = i
	_center = center / total if total > 0.0 else player.position
	density = clampf(total / 75.0, 0.0, 1.0)
	mix = clampf((nearby - 35.0) / 220.0, 0.0, 1.0)
	if touching >= 0 and _attack_cd <= 0.0:
		sfx.play("zombies/attack", horde.pos[touching], 2.5 if horde.elite[touching] else -2.0)
		_attack_cd = 0.6
	for k in 2:
		var i := choices[k]
		if i < 0 or k == 1 and choices[0] == i or _rng.randf() > clampf(total / 40.0, 0.05, 0.8):
			continue
		var id := "zombies/groan"
		if horde.kind[i] == Horde.Kind.RUNNER:
			id = "zombies/runner"
		elif horde.kind[i] == Horde.Kind.FAT:
			id = "zombies/fat"
		sfx.play(id, horde.pos[i], 3.0 if horde.elite[i] else -3.0)


func _death(at: Vector2, _dir: Vector2, death: int, _facing: float, variant: int) -> void:
	if sfx._silent or at.distance_squared_to(player.position) > HEARING * HEARING:
		return
	# Толстяк получает разрыв в fat_burst один раз.
	if variant != 5:
		sfx.play("gore/gib" if death == Gore.Death.GIBS else "gore/splat", at, -2.0)
	if death in [Gore.Death.HEADSHOT, Gore.Death.DECAP, Gore.Death.BISECT]:
		sfx.play("gore/bone", at, -4.0)
	if _rng.randf() < 0.35:
		sfx.play("zombies/death", at, -4.0)


func _fat(at: Vector2, elite: bool) -> void:
	sfx.play("gore/gib", at, 1.0)
	sfx.play("zombies/fat", at, 3.0 if elite else 0.0)


func _spit(at: Vector2, _to: Vector2, _damage: float) -> void:
	sfx.play("zombies/spit", at, -1.0)
