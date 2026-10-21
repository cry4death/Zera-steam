class_name GunLabPanel
extends CanvasLayer
## Пульт не захватывает свободную часть экрана: там можно стрелять.

signal selected(gun: String)
signal fire
signal burst
var audio: GunLabAudio
var gun := "shotgun"
var root: PanelContainer
var body: VBoxContainer
var status: Label
var ab: Button
var _layer := 0
var _page := 0
const TITLES := ["Атака", "Тело / низ", "Механика", "Хвост / отражение"]
const LABELS := {"gain":"Громкость, дБ", "pitch":"Высота тона, ×", "start":"Начало записи, с", "length":"Длина, с", "fade":"Затухание, с", "delay":"Задержка, с", "pitch_random":"Разброс высоты, ±", "gain_random":"Разброс громкости, ±дБ", "volume":"Общая громкость, дБ", "low_cut":"Срез низа, Гц", "high_cut":"Срез верха, Гц", "bass":"Подъём низа, дБ", "mid":"Середина, дБ", "drive":"Насыщение", "attack":"Жёсткость атаки", "room":"Размер отражения", "wet":"Доля реверберации хвоста", "shake":"Тряска камеры, ×", "recoil":"Отдача, ×", "flash":"Вспышка, ×"}

func _ready() -> void:
	layer = 60
	root = PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	root.anchor_left = .37
	root.anchor_right = .99
	root.anchor_top = .025
	root.anchor_bottom = .975
	root.add_theme_constant_override("margin_left",12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.075,.08,.075,.98)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	root.add_theme_stylebox_override("panel", style)
	root.add_theme_font_size_override("font_size",19)
	add_child(root)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	root.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	var title := Label.new()
	title.text = "ЗВУК ОРУЖИЯ · ТИР"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_button(top,"Закрыть · F9",func() -> void: root.hide())
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(row)
	var guns := VBoxContainer.new()
	guns.custom_minimum_size.x = 158
	row.add_child(guns)
	for i in GunLabAudio.GUNS.size():
		var id: String = GunLabAudio.GUNS[i]
		_button(guns,GunLabAudio.NAMES[i],func() -> void: choose(id))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var pages := HBoxContainer.new()
	right.add_child(pages)
	_button(pages,"Слои",func() -> void: _page = 0; rebuild())
	_button(pages,"Обработка и ощущение",func() -> void: _page = 1; rebuild())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",8)
	scroll.add_child(body)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	_button(actions,"Выстрел",func() -> void: fire.emit())
	_button(actions,"Очередь · 2 с",func() -> void: burst.emit())
	ab = _button(actions,"A/B: настройка",_compare)
	_button(actions,"Сохранить",func() -> void: status.text = audio.save_tuning(); _sync_ab())
	var edit := HBoxContainer.new()
	layout.add_child(edit)
	_button(edit,"Сбросить",func() -> void: audio.tuning[gun] = audio.defaults[gun].duplicate(true); _changed(); rebuild())
	var copy := OptionButton.new()
	copy.add_item("Скопировать с …",0)
	for i in GunLabAudio.GUNS.size():
		copy.add_item(GunLabAudio.NAMES[i],i+1)
	edit.add_child(copy)
	copy.item_selected.connect(func(index: int) -> void:
		if index > 0:
			audio.tuning[gun] = audio.tuning[GunLabAudio.GUNS[index-1]].duplicate(true)
			_changed()
			rebuild()
			copy.select(0))
	status = Label.new()
	status.text = "Слева от пульта — стрельба мышью. Изменения слышны со следующего выстрела."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	rebuild()
	root.hide()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func choose(id: String) -> void:
	gun = id
	selected.emit(gun)
	rebuild()

func toggle() -> void:
	root.visible = not root.visible

func _compare() -> void:
	audio.compare = not audio.compare
	for id: String in GunLabAudio.GUNS:
		audio.apply(id)
		audio.prepare(id)
	_sync_ab()
	status.text = "Играет сохранённое. A/B вернёт настройку." if audio.compare else "Играет текущая настройка."

func _sync_ab() -> void:
	ab.text = "A/B: сохранённое" if audio.compare else "A/B: настройка"

func _changed() -> void:
	audio.compare = false
	_sync_ab()
	audio.apply(gun)
	audio.prepare(gun)
	status.text = GunLabAudio.NAMES[GunLabAudio.GUNS.find(gun)] + " · есть несохранённые изменения"

func rebuild() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = GunLabAudio.NAMES[GunLabAudio.GUNS.find(gun)]
	body.add_child(heading)
	if _page == 0:
		var tabs := OptionButton.new()
		for title: String in TITLES:
			tabs.add_item(title)
		tabs.select(_layer)
		tabs.item_selected.connect(func(index: int) -> void: _layer = index; rebuild())
		body.add_child(tabs)
		var source_row := HBoxContainer.new()
		body.add_child(source_row)
		var select := OptionButton.new()
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.fit_to_longest_item = false
		select.add_item("Выкл")
		var sources: Array[String] = [""]
		for id: String in GunLabAudio.GUNS:
			for source: String in audio.catalog[id]:
				sources.append(source)
				select.add_item(GunLabAudio.NAMES[GunLabAudio.GUNS.find(id)]+" · "+_source_name(source))
		select.select(maxi(0,sources.find(audio.tuning[gun].layers[_layer].source)))
		select.item_selected.connect(func(index: int) -> void: audio.tuning[gun].layers[_layer].source = sources[index]; _changed())
		source_row.add_child(select)
		_button(source_row,"Прослушать",func() -> void: audio.preview(audio.tuning[gun].layers[_layer].source))
		for key: String in GunLabAudio.LAYER_LIMITS:
			_slider(key,audio.tuning[gun].layers[_layer],GunLabAudio.LAYER_LIMITS[key])
	else:
		for key: String in GunLabAudio.LIMITS:
			_slider(key,audio.tuning[gun],GunLabAudio.LIMITS[key])

func _source_name(source: String) -> String:
	return source.get_file().get_basename().replace("raw_mic","Отдельный микрофон").replace("mechanism","Механика").replace("close","близко").replace("mid","средняя дистанция").replace("_"," ")

func _slider(key: String, data: Dictionary, bounds: Array) -> void:
	var row := HBoxContainer.new()
	body.add_child(row)
	var name_label := Label.new()
	name_label.text = LABELS[key]
	name_label.custom_minimum_size.x = 255
	row.add_child(name_label)
	var value := Label.new()
	value.custom_minimum_size.x = 78
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var scale := 100.0 if key == "pitch_random" else 1.0
	if key == "pitch_random":
		name_label.text = "Разброс высоты, ±%"
	value.text = "%.3f" % (float(data[key])*scale)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 80
	slider.min_value = float(bounds[0])*scale
	slider.max_value = float(bounds[1])*scale
	slider.step = 1.0 if key in ["low_cut","high_cut"] else .001*scale
	slider.value = float(data[key])*scale
	row.add_child(slider)
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void: data[key] = v/scale; value.text = "%.3f" % v; _changed())
