extends Control

@onready var master_slider: HSlider = $PanelContainer/VBoxContainer/MasterSlider
@onready var background_slider: HSlider = $PanelContainer/VBoxContainer/BackgroundSlider
@onready var ui_slider: HSlider = $PanelContainer/VBoxContainer/UISlider
@onready var english_button: Button = $PanelContainer/VBoxContainer/LanguageButtons/EnglishButton
@onready var french_button: Button = $PanelContainer/VBoxContainer/LanguageButtons/FrenchButton
@onready var back_button: Button = $PanelContainer/VBoxContainer/BackButton
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var volume_label: Label = $PanelContainer/VBoxContainer/VolumeLabel
@onready var master_label: Label = $PanelContainer/VBoxContainer/MasterLabel
@onready var music_label: Label = $PanelContainer/VBoxContainer/MusicLabel
@onready var ui_label: Label = $PanelContainer/VBoxContainer/UILabel
@onready var language_label: Label = $PanelContainer/VBoxContainer/LanguageLabel
@onready var remap_container: VBoxContainer = $PanelContainer/VBoxContainer/RemapContainer

var pending_action: StringName = ""
var remap_buttons: Dictionary = {}
var remap_labels: Dictionary = {}

func _ready() -> void:
	master_slider.value = GameSettings.master_volume
	background_slider.value = GameSettings.background_volume
	ui_slider.value = GameSettings.ui_volume
	apply_text()
	build_remap_ui()

	master_slider.value_changed.connect(_on_master_changed)
	background_slider.value_changed.connect(_on_background_changed)
	ui_slider.value_changed.connect(_on_ui_changed)
	english_button.pressed.connect(func() -> void: _set_language("English"))
	french_button.pressed.connect(func() -> void: _set_language("Français"))
	back_button.pressed.connect(_on_back_pressed)
	set_process_unhandled_input(true)

func apply_text() -> void:
	title_label.text = GameSettings.get_text("settings")
	volume_label.text = GameSettings.get_text("volume")
	master_label.text = GameSettings.get_text("master")
	music_label.text = GameSettings.get_text("music")
	ui_label.text = GameSettings.get_text("ui")
	language_label.text = GameSettings.get_text("language")
	english_button.text = "English"
	french_button.text = "Français"
	back_button.text = GameSettings.get_text("back")
	for action in remap_buttons:
		remap_buttons[action].text = _display_for_action(action)

func _on_master_changed(value: float) -> void:
	GameSettings.master_volume = value

func _on_background_changed(value: float) -> void:
	GameSettings.background_volume = value

func _on_ui_changed(value: float) -> void:
	GameSettings.ui_volume = value

func _set_language(lang: String) -> void:
	GameSettings.language = lang
	apply_text()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func build_remap_ui() -> void:
	for child in remap_container.get_children():
		child.queue_free()
	remap_buttons.clear()
	remap_labels.clear()

	var actions: Array = ["move_up", "move_down", "move_left", "move_right", "rotate", "opacity_down", "opacity_up", "scale_up", "scale_down", "select"]
	for action in actions:
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		remap_container.add_child(row)

		var label: Label = Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		remap_labels[action] = label

		var button: Button = Button.new()
		button.text = _display_for_action(action)
		button.pressed.connect(_on_remap_pressed.bind(action))
		row.add_child(button)
		remap_buttons[action] = button

func _on_remap_pressed(action: StringName) -> void:
	pending_action = action
	for button in remap_buttons.values():
		button.disabled = true
	remap_buttons[action].disabled = false
	remap_buttons[action].text = "_"

func _unhandled_input(event: InputEvent) -> void:
	if pending_action == "":
		return
	if event is InputEventKey:
		if event.pressed and not event.echo:
			_apply_remap_key(pending_action, event.keycode)
	elif event is InputEventMouseButton:
		if event.pressed:
			_apply_remap_mouse(pending_action, event.button_index)

func _apply_remap_key(action: StringName, keycode: int) -> void:
	var new_event: InputEventKey = InputEventKey.new()
	new_event.keycode = keycode
	if _is_conflicting(action, new_event):
		pending_action = ""
		for button in remap_buttons.values():
			button.disabled = false
		remap_buttons[action].text = _display_for_action(action)
		return
	_update_action_binding(action, new_event)
	pending_action = ""
	for button in remap_buttons.values():
		button.disabled = false
	remap_buttons[action].text = _display_for_action(action)

func _apply_remap_mouse(action: StringName, button_index: int) -> void:
	var new_event: InputEventMouseButton = InputEventMouseButton.new()
	new_event.button_index = button_index
	if _is_conflicting(action, new_event):
		pending_action = ""
		for button in remap_buttons.values():
			button.disabled = false
		remap_buttons[action].text = _display_for_action(action)
		return
	_update_action_binding(action, new_event)
	pending_action = ""
	for button in remap_buttons.values():
		button.disabled = false
	remap_buttons[action].text = _display_for_action(action)

func _update_action_binding(action: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	GameSettings.keybinds[action] = _event_value(event)

func _is_conflicting(action: StringName, event: InputEvent) -> bool:
	var current_value = _event_value(event)
	for other_action in GameSettings.keybinds.keys():
		if other_action == action:
			continue
		if GameSettings.keybinds[other_action] == current_value:
			return true
	return false

func _display_for_action(action: StringName) -> String:
	var value = GameSettings.keybinds.get(action, null)
	if value is int:
		if value == MOUSE_BUTTON_LEFT:
			return "LMB"
		if value >= KEY_0 and value <= KEY_Z:
			return char(value)
		return str(value)
	return "?"

func _event_value(event: InputEvent) -> Variant:
	if event is InputEventKey:
		return event.keycode
	if event is InputEventMouseButton:
		return event.button_index
	return null
