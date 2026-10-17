class_name BloodAlarm
extends Node
## Кровавая тревога (MVP §8): в 7:00 3 с предупреждения → 30 с тревоги → контейнер.
## Логика только здесь: оверлей рисует AlarmOverlay, спавн берёт строку тревоги у Spawner,
## красный свет мира — CanvasModulate. Контейнер и его открытие делает S3 по сигналу.

signal container_dropped(pos: Vector2)

enum Phase { IDLE, WARN, ACTIVE, DONE }

const START := 420.0 # 7:00
const WARN_TIME := 3.0
const DURATION := 30.0
const ELITES := 4
const REWARD_MULT := 2.0 # опыт и кредиты во время тревоги
const CONTAINER_DISTANCE := 60.0
const TINT := Color(1.0, 0.75, 0.72)
const TINT_TIME := 0.5

var spawner: Spawner
var player: Player
var overlay: AlarmOverlay
var tint: CanvasModulate
var time := 0.0 # время забега, ставит игра
var verbose := false # печатать события (--sim, --alarm)
var phase: Phase = Phase.IDLE

var _k := 0.0 # насколько включён красный свет, 0..1


func _physics_process(delta: float) -> void:
	match phase:
		Phase.IDLE:
			if time >= START + WARN_TIME + DURATION:
				phase = Phase.DONE # перемотали мимо тревоги — пропускаем
			elif time >= START + WARN_TIME:
				_activate()
			elif time >= START:
				phase = Phase.WARN
				overlay.warn(START + WARN_TIME - time)
				_log("warn")
		Phase.WARN:
			if time >= START + WARN_TIME:
				_activate()
		Phase.ACTIVE:
			if time >= START + WARN_TIME + DURATION:
				_finish()
	_k = move_toward(_k, 1.0 if phase == Phase.ACTIVE else 0.0, delta / TINT_TIME)
	tint.color = Color.WHITE.lerp(TINT, _k)


## Множитель опыта и кредитов за убийство.
func reward_mult() -> float:
	return REWARD_MULT if phase == Phase.ACTIVE else 1.0


func is_active() -> bool:
	return phase == Phase.ACTIVE


func _activate() -> void:
	phase = Phase.ACTIVE
	spawner.alarm = true
	spawner.spawn_elites(ELITES)
	overlay.start(START + WARN_TIME + DURATION - time)
	_log("start")


func _finish() -> void:
	phase = Phase.DONE
	spawner.alarm = false
	overlay.finish()
	var dir := player.facing if player.facing != Vector2.ZERO else Vector2.RIGHT
	var p := (player.global_position + dir * CONTAINER_DISTANCE).clamp(
		player.arena.position + Vector2.ONE * 20.0, player.arena.end - Vector2.ONE * 20.0)
	_log("finish container=%s" % p)
	container_dropped.emit(p)


func _log(what: String) -> void:
	if verbose:
		print("ALARM_EVENT %s time=%02d:%02d" % [what, int(time) / 60, int(time) % 60])
