extends SceneTree
## Отдельный процесс читает только проверочный файл; настройки автора не трогает.

func _initialize() -> void:
	var audio := GunLabAudio.new()
	audio.audible = false
	root.add_child(audio)
	_run.call_deferred(audio)

func _run(audio: GunLabAudio) -> void:
	var text := FileAccess.get_file_as_string("res://design/tasks/reports/w6_reload.json")
	var decoded := audio.decode(text)
	var expected: Dictionary = JSON.parse_string(text).guns
	var ok: bool = decoded == expected and decoded.shotgun.layers[0].gain == -9.125
	print("GUNLAB RELOAD exact=%s" % ok)
	quit(0 if ok else 1)
