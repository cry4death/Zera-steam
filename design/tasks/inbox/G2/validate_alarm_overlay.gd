extends SceneTree
## Запускать только в отдельной копии проекта.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(layer)
	var alarm := AlarmOverlay.new()
	layer.add_child(alarm)
	alarm.set_process(false)
	_check(not alarm.visible and not alarm.is_active(), "initially hidden and inactive")
	_check(alarm.get_child_count() == 0, "single Control, no child nodes")
	_check(alarm.anchor_left == 0.0 and alarm.anchor_top == 0.0 and alarm.anchor_right == 1.0 and alarm.anchor_bottom == 1.0, "full-screen anchors")
	_check(alarm.mouse_filter == Control.MOUSE_FILTER_IGNORE and alarm.focus_mode == Control.FOCUS_NONE, "mouse and focus pass through")
	_check(alarm.process_mode == Node.PROCESS_MODE_PAUSABLE, "pause is respected under an ALWAYS parent")
	alarm.warn(3.0)
	alarm.set_process(false)
	_check(alarm.visible and alarm.is_active() and alarm._detail == "через 3", "warn starts at 3")
	alarm._process(0.125)
	_check(alarm._stripe_amount > 0.0 and alarm._stripe_amount < 1.0 and alarm._blink, "warning stripes enter during first 0.25 seconds")
	alarm._process(0.125)
	_check(is_equal_approx(alarm._stripe_amount, 1.0) and not alarm._blink, "stripes fully entered and title blink is hard")
	alarm._process(0.25)
	_check(alarm._blink, "warning title repeats at 2 Hz")
	alarm._process(0.5)
	_check(alarm._detail == "через 2", "warning countdown 2")
	alarm._process(1.0)
	_check(alarm._detail == "через 1", "warning countdown 1")
	alarm.start(30.0)
	alarm.set_process(false)
	_check(alarm.is_active() and alarm._phase == AlarmOverlay.Phase.ACTIVE and alarm._detail.ends_with("0:30"), "start replaces warning and shows 0:30")
	_check(alarm._flash_alpha <= 0.12 and alarm._stripe_amount == 1.0, "initial flash respects central alpha limit")
	alarm._process(0.11)
	_check(is_equal_approx(alarm._edge_alpha, 0.45), "first heartbeat reaches edge alpha 0.45")
	alarm._process(0.22)
	_check(is_equal_approx(alarm._edge_alpha, 0.405), "second heartbeat is weaker")
	_check(alarm._flash_alpha == 0.0, "full-screen flash ends by 0.3 seconds")
	alarm._process(0.07)
	_check(is_zero_approx(alarm._stripe_amount), "stripes leave by 0.4 seconds")
	alarm._process(6.6)
	_check(alarm._detail == "опыт и кредиты x2    0:23", "bonus and remaining time are cached text")
	alarm._process(18.0)
	var phase_before := alarm._heartbeat_phase
	alarm._process(0.06)
	_check(is_equal_approx(fposmod(alarm._heartbeat_phase - phase_before, 1.0), 0.1), "last five seconds use 0.6-second heartbeat period")
	var edge_before := alarm._edge_alpha
	alarm.finish()
	alarm.set_process(false)
	_check(alarm.visible and not alarm.is_active() and alarm._phase == AlarmOverlay.Phase.FINISH, "finish is visible but not active")
	alarm._process(0.75)
	_check(is_equal_approx(alarm._edge_alpha, edge_before * 0.5), "finish halves vignette opacity at 0.75 seconds")
	alarm.finish()
	_check(is_equal_approx(alarm._elapsed, 0.75), "repeated finish does not restart fade")
	alarm._process(0.75)
	_check(not alarm.visible and not alarm.is_processing(), "finish hides and stops processing after 1.5 seconds")
	alarm.warn(0.0)
	_check(not alarm.visible and not alarm.is_active(), "zero warning duration stays hidden")
	alarm.start(-1.0)
	_check(not alarm.visible and not alarm.is_active(), "negative alarm duration stays hidden")
	alarm.start(NAN)
	_check(not alarm.visible, "non-finite duration is rejected")
	alarm.start(1.0)
	alarm.set_process(false)
	alarm._process(1.0)
	alarm.set_process(false)
	_check(alarm._phase == AlarmOverlay.Phase.FINISH and not alarm.is_active(), "alarm automatically finishes when duration expires")
	alarm.stop()
	_check(not alarm.visible and not alarm.is_processing() and alarm._elapsed == 0.0 and alarm._stripe_amount == 0.0 and alarm._flash_alpha == 0.0, "stop clears and hides immediately")
	alarm.warn(3.0)
	alarm.set_process(false)
	alarm._process(3.0)
	_check(not alarm.visible and not alarm.is_active(), "warning expiry never starts the game alarm by itself")
	alarm.start(1.0)
	alarm.set_process(false)
	alarm._process(3.0)
	_check(not alarm.visible and not alarm.is_processing(), "large delta handles alarm expiry and full result fade")
	alarm.reduced_motion = true
	alarm.warn(3.0)
	alarm.set_process(false)
	alarm._process(0.3)
	_check(alarm._blink and alarm._stripe_offset == 0.0 and alarm._stripe_amount == 1.0, "reduced motion keeps warning stable")
	alarm.start(30.0)
	alarm.set_process(false)
	alarm._process(0.1)
	_check(alarm._flash_alpha == 0.0 and alarm._stripe_amount == 0.0 and alarm._edge_alpha == 0.35, "reduced motion removes flash and heartbeat")
	alarm.reduced_motion = false
	alarm.warn(3.0)
	paused = true
	var frozen_elapsed := alarm._elapsed
	var frozen_remaining := alarm._remaining
	await process_frame
	await process_frame
	_check(alarm._elapsed == frozen_elapsed and alarm._remaining == frozen_remaining, "actual tree pause freezes warning under ALWAYS layer")
	paused = false
	await process_frame
	await process_frame
	_check(alarm._elapsed > frozen_elapsed, "warning resumes after unpause")
	alarm.start(30.0)
	paused = true
	frozen_remaining = alarm._remaining
	await process_frame
	await process_frame
	_check(alarm._remaining == frozen_remaining, "actual tree pause freezes active alarm")
	paused = false
	alarm.finish()
	paused = true
	frozen_remaining = alarm._remaining
	await process_frame
	await process_frame
	_check(alarm._remaining == frozen_remaining, "actual tree pause freezes result fade")
	paused = false
	alarm.stop()
	var vignette := alarm._vignette
	var stripes := alarm._stripes
	alarm.warn(3.0)
	alarm.start(30.0)
	alarm.finish()
	alarm.stop()
	_check(alarm._vignette == vignette and alarm._stripes == stripes, "textures are reused across phases")
	await process_frame
	await process_frame
	var image := vignette.get_image()
	var center_clear := image != null and not image.is_empty()
	if center_clear:
		for y in range(103, 409, 8):
			for x in range(103, 409, 8):
				if image.get_pixel(x, y).a > 0.005:
					center_clear = false
	if image == null and DisplayServer.get_name() == "headless":
		print("SKIP: gradient pixel readback unavailable with dummy renderer; use render_alarm_overlay.gd")
	else:
		_check(center_clear, "vignette is transparent throughout central 60 percent rectangle")
	_check(alarm.get_child_count() == 0, "phase changes create no child nodes")
	print("RESULT: failures=", _failures)
	quit(0 if _failures == 0 else 1)
