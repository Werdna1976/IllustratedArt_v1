extends Control
## Title screen: background art stretched to cover any window (edges crop, no bars), looping
## theme music, and a keyboard/gamepad menu. Swap in a 3840x2160 title_bg.png later; no code change.

const BACKGROUND := preload("res://art/ui/title_bg.png")
const THEME_MUSIC := preload("res://audio/music/title_theme.ogg")
const ACCENT := Color("#39f3ff")
const MENU_TOP := 0.70 ## Fraction of screen height where the menu starts (the fog band in title_bg.png).

var background: TextureRect
var music: AudioStreamPlayer
var start_button: Button
var start_scene := "res://scenes/level/level_1.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	background = TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_build_menu()
	var theme_music: AudioStreamOggVorbis = THEME_MUSIC
	theme_music.loop = true
	music = AudioStreamPlayer.new()
	music.stream = theme_music
	add_child(music)
	music.play()
	start_button.grab_focus()


func _build_menu() -> void:
	var menu := VBoxContainer.new()
	# Sits in the open band of the background art; proportional anchors keep
	# it there as the covered background scales with the window.
	menu.anchor_left = 0.5
	menu.anchor_right = 0.5
	menu.anchor_top = MENU_TOP
	menu.anchor_bottom = MENU_TOP
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.add_theme_constant_override("separation", 10)
	add_child(menu)
	start_button = _button(menu, "START", func() -> void: get_tree().change_scene_to_file(start_scene))
	_button(menu, "COMBAT SANDBOX", func() -> void: get_tree().change_scene_to_file("res://scenes/level/combat_sandbox.tscn"))
	_button(menu, "QUIT", func() -> void: get_tree().quit())


func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 54)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_focus_color", ACCENT)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.add_theme_stylebox_override("normal", _box(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.15)))
	button.add_theme_stylebox_override("hover", _box(Color(0, 0, 0, 0.6), ACCENT))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0.6), ACCENT))
	button.add_theme_stylebox_override("pressed", _box(Color(ACCENT, 0.25), ACCENT))
	button.pressed.connect(on_press)
	parent.add_child(button)
	return button


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	return box
