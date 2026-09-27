class_name GameInput
extends RefCounted
## Registers the game's input actions at runtime so project.godot stays hand-editable.

const KEYS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"jump": [KEY_SPACE, KEY_W, KEY_UP],
	&"light_attack": [KEY_J],
	&"heavy_attack": [KEY_K],
	&"launcher": [KEY_I],
	&"parry": [KEY_L],
	&"dodge": [KEY_SHIFT],
}
const PAD_BUTTONS := {
	&"move_left": JOY_BUTTON_DPAD_LEFT,
	&"move_right": JOY_BUTTON_DPAD_RIGHT,
	&"jump": JOY_BUTTON_A,
	&"light_attack": JOY_BUTTON_X,
	&"heavy_attack": JOY_BUTTON_Y,
	&"launcher": JOY_BUTTON_RIGHT_SHOULDER,
	&"parry": JOY_BUTTON_LEFT_SHOULDER,
	&"dodge": JOY_BUTTON_B,
}


static func ensure_actions() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		var pad := InputEventJoypadButton.new()
		pad.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, pad)
