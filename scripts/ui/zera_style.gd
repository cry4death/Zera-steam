extends RefCounted
## Общий язык базы: металл, брезент и маркировка оружейного поста.

const TITLE_FONT := preload("res://fonts/russo_one/RussoOne-Regular.ttf")
const BODY_FONT := preload("res://fonts/fira_sans_condensed/FiraSansCondensed-Regular.ttf")
const TITLE := 24
const SUBTITLE := 13
const BODY := 10
const NUMBER := 22
const SMALL := 8
const NAV := 8
const HEADER := 32.0
const GAP := 8.0
const MARGIN := 12.0
const METAL := Color("151b1b")
const RECESS := Color("101515")
const CANVAS := Color("242d28")
const HOVER := Color("354139")
const TEXT := Color("e0ded1")
const MUTED := Color("a5afa3")
const DISABLED := Color("69766d")
const SELECTED := Color("c1c4ab")
const ACTION := Color("c9ac65")
const DANGER := Color("c27668")
const BETTER := Color("a5bb91")
const RARE := Color("9daeb7")
const CLOTH := preload("res://art/ui_canvas.png")

## Материал остановленного боя: тот же брезент, что в оружейной.
static func cloth(item: CanvasItem, rect: Rect2) -> void:
	item.draw_rect(rect, CANVAS)
	item.draw_texture_rect(CLOTH, rect, false, Color(1, 1, 1, 0.45))


static func card_color(card: Dictionary) -> Color:
	if card.get("rare", false):
		return RARE
	if card.get("type", "") == "weapon":
		var model: String = card.get("model", Meta.model_for(card.get("id", 0)))
		return RARE if WeaponDefs.MODELS[model]["rarity"] == WeaponDefs.Rarity.RARE else ACTION
	return BETTER if card.get("type", "") == "passive" else TEXT

enum State { NORMAL, HOVERED, SELECTED, DISABLED, LOCKED }

static func cut_rect(item: CanvasItem, rect: Rect2, color: Color, cut := 3.0) -> void:
	var p := rect.position
	var e := rect.end
	item.draw_colored_polygon(PackedVector2Array([p, Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut), e, Vector2(p.x, e.y)]), color)

static func surface(item: CanvasItem, rect: Rect2, state: int) -> void:
	var fill := CANVAS
	if state == State.HOVERED: fill = HOVER
	if state == State.SELECTED: fill = Color("3c463b")
	if state == State.DISABLED: fill = METAL
	cut_rect(item, rect, fill)
	if state == State.SELECTED:
		item.draw_rect(Rect2(rect.position, Vector2(2, rect.size.y)), SELECTED)

static func lock_icon(item: CanvasItem, at: Vector2, color: Color) -> void:
	item.draw_rect(Rect2(at + Vector2(-2, -4), Vector2(4, 4)), color, false, 1.0)
	item.draw_rect(Rect2(at + Vector2(-3, 0), Vector2(6, 5)), color)
	item.draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 2)), RECESS)


## Короткое подтверждение: общий материал и метка, без заставки.
static func reward(item: CanvasItem, rect: Rect2, remaining: float) -> void:
	cut_rect(item, rect, RECESS)
	item.draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), BETTER)
	item.draw_rect(Rect2(rect.position + Vector2(3, rect.size.y - 1), Vector2((rect.size.x - 3) * minf(1.0, remaining), 1)), BETTER)
