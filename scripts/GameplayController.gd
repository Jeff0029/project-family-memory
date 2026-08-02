extends Node2D

@export_range(0.1, 5.0) var placement_delay_seconds: float = 1.0
@export_range(1, 20) var countdown_seconds: int = 5
@export_range(5, 120) var gameplay_timer: int = 20
@export_range(1, 10) var rounds: int = 3
@export_range(1, 8) var pictures_per_row: int = 4
@export_range(10, 5000) var min_pixels_squared: int = 100
@export_range(0.1, 1.0) var min_opacity: float = 0.5
@export_range(0.1, 1.0) var max_opacity: float = 1.0
@export_range(100, 5000) var max_score: int = 1000
@export_range(0.0, 1.0) var zoom_padding: float = 0.1
@export_range(0.25, 10.0) var camera_zoom_min: float = 0.5
@export_range(0.25, 10.0) var camera_zoom_max: float = 3.0
@export_range(0.1, 10.0) var photo_zoom_min: float = 0.25
@export_range(0.1, 10.0) var photo_zoom_max: float = 3.0
@export_range(0.05, 1.0) var starting_hidden_photo_scale: float = 0.33
@export_range(0.1, 10.0) var fade_overlay_duration_seconds: float = 0.6
@export_range(0.1, 10.0) var fade_overlay_on_duration: float = 0.6
@export_range(0.1, 10.0) var found_photo_wait_seconds: float = 3.0

@onready var backdrop: ColorRect = $Backdrop
@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var hidden_photo: Sprite2D = $HiddenPhoto
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var camera_2d: Camera2D = $Camera2D
@onready var round_label: Label = $CanvasLayer/UI/RoundLabel

var camera_center: Node2D
@onready var status_label: Label = $CanvasLayer/UI/StatusLabel
@onready var timer_label: Label = $CanvasLayer/UI/TimerLabel
@onready var score_label: Label = $CanvasLayer/UI/ScoreLabel
@onready var narrative_label: Label = $CanvasLayer/UI/NarrativeLabel
@onready var final_overlay: Control = $CanvasLayer/FinalOverlay
@onready var rematch_button: Button = $CanvasLayer/FinalOverlay/VBoxContainer/RematchButton
@onready var menu_button: Button = $CanvasLayer/FinalOverlay/VBoxContainer/MenuButton
@onready var exit_button: Button = $CanvasLayer/FinalOverlay/VBoxContainer/ExitButton
@onready var final_scores_label: Label = $CanvasLayer/FinalOverlay/VBoxContainer/FinalScoresLabel
@onready var winner_label: Label = $CanvasLayer/FinalOverlay/VBoxContainer/WinnerLabel

var background_paths: Array[String] = []
var photo_paths: Array[String] = []
var current_background_texture: Texture2D
var current_photo_texture: Texture2D
var selected_photo_path: String = ""
var selected_background_path: String = ""
var gallery_panel: Control
var gallery_grid: GridContainer
var submit_button: Button
var hidden_photo_button: TextureButton
var hidden_photo_area: Area2D
var hidden_photo_hit_shape: CollisionShape2D
var current_round: int = 0
var current_player: int = 0
var scores: Array[int] = [0, 0]
var state: String = "idle"
var placement_timer: float = 0.0
var search_timer: float = 0.0
var narrative_index: int = 0
var narrative_timer: float = 0.0
var search_started_at: int = 0
var hidden_photo_placed: bool = false
var placement_locked: bool = false
var placement_position: Vector2 = Vector2.ZERO
var placement_rotation: float = 0.0
var current_photo_rotation: float = 0.0
var final_score_value: int = 0
var is_dragging_photo: bool = false
var is_rotating_photo: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var zoom_tween: Tween
var hold_repeat_state: Dictionary = {}
var narrative_lines: Array[String] = [
	"Every love story deserves a celebration.",
	"This hidden memory is a tiny tribute to forty years of togetherness.",
	"May every round feel like a cherished wedding memory."
]

var hidden_photo_controller: HiddenPhotoController
var find_the_memory_controller: FindTheMemory
var calculate_scoring_controller: CalculateScoring
var ui_text_controller: UITextController
var camera_controls_enabled: bool = true

func _ready() -> void:
	register_input_actions()
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 1)
	final_overlay.visible = false
	background_sprite.visible = false
	hidden_photo.visible = false
	create_hidden_photo_button()
	camera_center = get_node_or_null("CameraCenter") as Node2D

	hidden_photo_controller = HiddenPhotoController.new()
	hidden_photo_controller.initialize(self)
	add_child(hidden_photo_controller)

	find_the_memory_controller = FindTheMemory.new()
	find_the_memory_controller.initialize(self)
	add_child(find_the_memory_controller)

	calculate_scoring_controller = CalculateScoring.new()
	calculate_scoring_controller.initialize(self)
	add_child(calculate_scoring_controller)

	ui_text_controller = UITextController.new()
	ui_text_controller.initialize(self)
	add_child(ui_text_controller)

	load_assets()
	build_gallery()
	create_submit_button()
	rematch_button.pressed.connect(_on_rematch_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	update_ui_visibility()
	start_game()

func _process(delta: float) -> void:
	if state == "placing":
		update_press_and_hold_actions(delta)
		if is_rotating_photo:
			update_photo_rotation_from_mouse()
		elif is_dragging_photo:
			update_photo_position_from_mouse()
		elif camera_controls_enabled:
			move_camera(delta)
		update_ui_visibility()
	elif state == "searching":
		if camera_controls_enabled:
			move_camera(delta)
		search_timer -= delta
		update_timer_label(int(ceil(search_timer)))
		if search_timer <= 0:
			finish_round(false)
	elif state == "waiting_to_search":
		placement_timer -= delta
		if placement_timer <= 0:
			state = "search_transition"
			start_search_phase()
	elif state == "narrating":
		narrative_timer -= delta
		if narrative_timer <= 0:
			advance_narrative()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if state == "placing":
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				handle_wheel_zoom(true)
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				handle_wheel_zoom(false)
				return
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					var clicked_on_photo: bool = is_mouse_on_photo(get_global_mouse_position())
					reset_interaction_state()
					if clicked_on_photo:
						is_rotating_photo = true
					last_mouse_position = get_global_mouse_position()
				else:
					reset_interaction_state()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if event.pressed:
					var clicked_on_photo: bool = is_mouse_on_photo(get_global_mouse_position())
					reset_interaction_state()
					if clicked_on_photo:
						is_dragging_photo = true
					last_mouse_position = get_global_mouse_position()
				else:
					reset_interaction_state()
		elif state == "searching":
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				handle_wheel_zoom(true)
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				handle_wheel_zoom(false)
				return
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				try_find_photo(event.position)

func is_mouse_on_photo(mouse_position: Vector2) -> bool:
	if not hidden_photo.visible:
		return false
	var half_size: Vector2 = hidden_photo.texture.get_size() * hidden_photo.scale * 0.5
	var sprite_rect: Rect2 = Rect2(hidden_photo.global_position - half_size, hidden_photo.texture.get_size() * hidden_photo.scale)
	return sprite_rect.has_point(mouse_position)

func start_game() -> void:
	current_round = 0
	scores = [0, 0]
	current_player = 0
	state = "narrating"
	show_narrative()
	update_score_label()
	start_round()

func start_round() -> void:
	current_round += 1
	if current_round > rounds:
		show_final_scores()
		return
	selected_photo_path = ""
	placement_locked = false
	hidden_photo_placed = false
	placement_rotation = 0.0
	current_photo_rotation = 0.0
	hold_repeat_state.clear()
	reset_interaction_state()
	state = "placing"
	prepare_round_assets()
	status_label.text = ui_text_controller.get_status_place_text()
	round_label.text = ui_text_controller.get_round_text(current_round)
	timer_label.text = ""
	background_sprite.visible = true
	hidden_photo.visible = false
	hidden_photo_button.visible = false
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 0)
	show_narrative()
	update_ui_visibility()

func prepare_round_assets() -> void:
	var background_path: String = selected_background_path if selected_background_path != "" else background_paths[randi() % background_paths.size()]
	var photo_path: String = selected_photo_path if selected_photo_path != "" else photo_paths[randi() % photo_paths.size()]
	current_background_texture = load(background_path)
	current_photo_texture = load(photo_path)
	background_sprite.texture = current_background_texture
	hidden_photo.texture = current_photo_texture
	hidden_photo.modulate = Color(1, 1, 1, 0.9)
	hidden_photo.rotation = 0.0
	current_photo_rotation = 0.0
	hidden_photo.visible = false
	apply_photo_scale_from_texture()
	var size: Vector2 = background_sprite.texture.get_size()
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	hidden_photo.position = center
	var visible_size: Vector2 = backdrop.size * 0.5
	hidden_photo.position = Vector2(randf_range(visible_size.x * 0.2, visible_size.x * 0.8), randf_range(visible_size.y * 0.2, visible_size.y * 0.8))
	sync_hidden_photo_button()
	var viewport_size: Vector2 = camera_2d.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)
	camera_2d.zoom = Vector2.ONE
	camera_2d.global_position = get_camera_target_position() - (viewport_size * 0.5) / camera_2d.zoom
	status_label.text = ui_text_controller.get_placing_text()

func place_hidden_photo() -> void:
	if placement_locked:
		return
	placement_locked = true
	hidden_photo_placed = true
	placement_position = hidden_photo.position
	current_photo_rotation = hidden_photo.rotation
	placement_rotation = current_photo_rotation
	hidden_photo.rotation = placement_rotation
	reset_interaction_state()
	state = "waiting_to_search"
	placement_timer = placement_delay_seconds
	status_label.text = ui_text_controller.get_searching_text()
	update_ui_visibility()

func start_search_phase() -> void:
	reset_interaction_state()
	hidden_photo.rotation = placement_rotation
	current_photo_rotation = placement_rotation
	hidden_photo.position = placement_position
	sync_hidden_photo_button()
	camera_controls_enabled = false
	hidden_photo_controller.apply_saved_transform()
	status_label.text = ui_text_controller.get_status_search_text()
	await find_the_memory_controller.start_search_transition()
	state = "searching"
	search_timer = gameplay_timer
	update_timer_label(gameplay_timer)
	await find_the_memory_controller.fit_camera_to_background()
	camera_controls_enabled = true
	update_ui_visibility()

func fit_camera_to_background() -> void:
	await get_tree().process_frame
	var viewport_size: Vector2 = camera_2d.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	var target_center: Vector2 = get_camera_target_position()
	var target_size: Vector2 = backdrop.size
	if background_sprite.texture != null:
		var sprite_size: Vector2 = background_sprite.texture.get_size() * background_sprite.scale
		target_size = sprite_size

	var padding_factor: float = max(1.0 + zoom_padding * 1.4, 1.0)
	var width_zoom: float = target_size.x / max(viewport_size.x * padding_factor, 1.0)
	var height_zoom: float = target_size.y / max(viewport_size.y * padding_factor, 1.0)
	var final_zoom: float = max(width_zoom, height_zoom)

	var zoom_vector: Vector2 = Vector2.ONE * clamp(final_zoom, camera_zoom_min, camera_zoom_max)
	camera_2d.make_current()
	camera_2d.zoom = zoom_vector
	camera_2d.global_position = target_center - (viewport_size * 0.5) / zoom_vector

func get_camera_target_position() -> Vector2:
	if camera_center != null:
		return camera_center.global_position
	if background_sprite != null:
		return background_sprite.global_position
	return backdrop.global_position + backdrop.size * 0.5

func finish_round(found: bool) -> void:
	reset_interaction_state()
	if state == "searching":
		state = "idle"
	var score: int = 0
	if found:
		hidden_photo.modulate = Color(1, 1, 1, max_opacity)
		score = calculate_score()
		scores[current_player] += score
		final_score_value = score
		status_label.text = ui_text_controller.get_final_message_text(score)
		update_score_label()
		await get_tree().create_timer(found_photo_wait_seconds).timeout
	else:
		status_label.text = "No match found."
		update_score_label()
		await get_tree().create_timer(1.2).timeout
	current_player = 1 - current_player
	start_round()

func calculate_score() -> int:
	var opacity_percent: float = remap(clamp(hidden_photo.modulate.a, min_opacity, max_opacity), min_opacity, max_opacity, 0.5, 1.0)
	var scale_percent: float = get_scale_percent_for_score()
	var time_percent: float = clamp(search_timer / float(gameplay_timer), 0.0, 1.0)
	return calculate_scoring_controller.calculate_score()

func get_scale_percent_for_score() -> float:
	return calculate_scoring_controller.get_scale_percent_for_score()

func update_score_label() -> void:
	score_label.text = ui_text_controller.get_score_label_text(scores)

func update_timer_label(value: int) -> void:
	timer_label.text = str(value)

func reset_interaction_state() -> void:
	is_dragging_photo = false
	is_rotating_photo = false
	if hidden_photo.visible and hidden_photo_placed:
		placement_position = hidden_photo.position

func update_photo_rotation_from_mouse() -> void:
	hidden_photo_controller.update_photo_rotation_from_mouse(get_global_mouse_position())

func update_photo_position_from_mouse() -> void:
	hidden_photo_controller.update_photo_position_from_mouse(get_global_mouse_position(), last_mouse_position)

func handle_wheel_zoom(zoom_in: bool) -> void:
	if is_dragging_photo:
		var delta: float = 0.1 if zoom_in else -0.1
		adjust_hidden_photo_scale(delta)
	else:
		var delta: float = 0.1 if zoom_in else -0.1
		adjust_camera_zoom(delta)

func adjust_camera_zoom(delta: float) -> void:
	var current_zoom: float = camera_2d.zoom.x
	var target_zoom: float = clamp(current_zoom + delta, camera_zoom_min, camera_zoom_max)
	if is_equal_approx(current_zoom, target_zoom):
		return
	if zoom_tween != null:
		zoom_tween.kill()
	zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(camera_2d, "zoom", Vector2.ONE * target_zoom, 0.12)

func adjust_hidden_photo_scale(delta: float) -> void:
	hidden_photo_controller.adjust_hidden_photo_scale(delta)

func get_min_scale_limit() -> float:
	return hidden_photo_controller.get_min_scale_limit()

func get_max_scale_limit() -> float:
	return hidden_photo_controller.get_max_scale_limit()

func apply_photo_scale_from_texture() -> void:
	hidden_photo_controller.apply_photo_scale_from_texture()

func update_press_and_hold_actions(delta: float) -> void:
	for action in ["opacity_down", "opacity_up", "scale_up", "scale_down"]:
		if Input.is_action_just_pressed(action):
			hold_repeat_state[action] = {"repeat_count": 0, "elapsed": 0.0}
			apply_placement_action(action)
		elif Input.is_action_pressed(action):
			if not hold_repeat_state.has(action):
				continue
			var hold_data: Dictionary = hold_repeat_state[action]
			hold_data["elapsed"] += delta
			var interval_seconds: float = get_repeat_interval_seconds(hold_data["repeat_count"])
			if hold_data["elapsed"] >= interval_seconds:
				hold_data["elapsed"] -= interval_seconds
				hold_data["repeat_count"] += 1
				apply_placement_action(action)
		else:
			hold_repeat_state.erase(action)

func get_repeat_interval_seconds(repeat_count: int) -> float:
	if repeat_count < 3:
		return 0.1
	if repeat_count == 3:
		return 0.14
	return 0.03

func apply_placement_action(action_name: String) -> void:
	match action_name:
		"scale_up":
			var next_scale_up: float = clamp(hidden_photo.scale.x * 1.05, get_min_scale_limit(), get_max_scale_limit())
			hidden_photo.scale = Vector2.ONE * next_scale_up
			sync_hidden_photo_button()
		"scale_down":
			var next_scale_down: float = clamp(hidden_photo.scale.x * 0.95, get_min_scale_limit(), get_max_scale_limit())
			hidden_photo.scale = Vector2.ONE * next_scale_down
			sync_hidden_photo_button()
		"opacity_up":
			hidden_photo.modulate.a = clamp(hidden_photo.modulate.a + 0.05, min_opacity, max_opacity)
		"opacity_down":
			hidden_photo.modulate.a = clamp(hidden_photo.modulate.a - 0.05, min_opacity, max_opacity)

func move_camera(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	camera_2d.position += direction * 400.0 * delta

func try_find_photo(position: Vector2) -> void:
	if not hidden_photo.visible:
		return
	var half_size: Vector2 = hidden_photo.texture.get_size() * hidden_photo.scale * 0.5
	var sprite_rect: Rect2 = Rect2(hidden_photo.global_position - half_size, hidden_photo.texture.get_size() * hidden_photo.scale)
	if sprite_rect.has_point(get_global_mouse_position()):
		_on_hidden_photo_pressed()

func create_hidden_photo_button() -> void:
	hidden_photo_button = TextureButton.new()
	hidden_photo_button.name = "HiddenPhotoButton"
	hidden_photo_button.visible = false
	hidden_photo_button.mouse_filter = Control.MOUSE_FILTER_PASS
	hidden_photo_button.modulate = Color(1, 1, 1, 0.0)
	hidden_photo_button.focus_mode = Control.FOCUS_NONE
	hidden_photo_button.pressed.connect(_on_hidden_photo_pressed)
	$CanvasLayer/UI.add_child(hidden_photo_button)

	hidden_photo_area = Area2D.new()
	hidden_photo_area.name = "HiddenPhotoArea"
	hidden_photo_area.input_pickable = true
	hidden_photo_area.monitoring = false
	hidden_photo_area.monitorable = false
	hidden_photo_area.visible = false
	hidden_photo_area.input_event.connect(_on_hidden_photo_input)
	add_child(hidden_photo_area)

	hidden_photo_hit_shape = CollisionShape2D.new()
	hidden_photo_hit_shape.name = "HiddenPhotoHitShape"
	var hit_shape: RectangleShape2D = RectangleShape2D.new()
	hidden_photo_hit_shape.shape = hit_shape
	hidden_photo_area.add_child(hidden_photo_hit_shape)

func sync_hidden_photo_button() -> void:
	hidden_photo_controller.sync_hidden_photo_button()

func _on_hidden_photo_input(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_hidden_photo_pressed()

func _on_hidden_photo_pressed() -> void:
	finish_round(true)

func build_gallery() -> void:
	gallery_panel = Control.new()
	gallery_panel.name = "GalleryPanel"
	gallery_panel.visible = false
	gallery_panel.anchor_left = 0.0
	gallery_panel.anchor_top = 1.0
	gallery_panel.anchor_right = 0.0
	gallery_panel.anchor_bottom = 1.0
	gallery_panel.position = Vector2(20, -340)
	gallery_panel.size = Vector2(900, 320)
	$CanvasLayer/UI.add_child(gallery_panel)

	var panel_style: PanelContainer = PanelContainer.new()
	panel_style.size = gallery_panel.size
	gallery_panel.add_child(panel_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_style.add_child(vbox)

	var label: Label = Label.new()
	label.text = ui_text_controller.get_choose_memory_text()
	vbox.add_child(label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	gallery_grid = GridContainer.new()
	gallery_grid.columns = pictures_per_row
	gallery_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(gallery_grid)

	for photo_path in photo_paths:
		var texture:Texture2D = load(photo_path)
		var image = texture.get_image()
		image.resize(256, 256)
		
		var button: TextureButton = TextureButton.new()
		button.custom_minimum_size = Vector2(72, 72)
		button.texture_normal = ImageTexture.create_from_image(image)
		#button.expand_icon = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(select_photo.bind(photo_path))
		button.tooltip_text = photo_path.get_file()
		gallery_grid.add_child(button)

func create_submit_button() -> void:
	submit_button = Button.new()
	submit_button.name = "SubmitButton"
	submit_button.text = "Submit"
	submit_button.visible = false
	submit_button.custom_minimum_size = Vector2(140, 40)
	submit_button.anchor_left = 1.0
	submit_button.anchor_top = 1.0
	submit_button.anchor_right = 1.0
	submit_button.anchor_bottom = 1.0
	submit_button.offset_left = -180
	submit_button.offset_top = -80
	submit_button.offset_right = -20
	submit_button.offset_bottom = -20
	submit_button.pressed.connect(_on_submit_pressed)
	$CanvasLayer/UI.add_child(submit_button)

func select_photo(photo_path: String) -> void:
	reset_interaction_state()
	selected_photo_path = photo_path
	if FileAccess.file_exists(photo_path):
		var texture: Texture2D = load(photo_path)
		hidden_photo.texture = texture
		hidden_photo_button.texture_normal = texture
		current_photo_texture = texture
		hidden_photo.rotation_degrees = 0.0
		hidden_photo.modulate = Color(1, 1, 1, 0.9)
		apply_photo_scale_from_texture()
		var mouse_position: Vector2 = get_global_mouse_position()
		hidden_photo.position = mouse_position
		hidden_photo.visible = true
		hidden_photo_button.visible = true
		sync_hidden_photo_button()
		status_label.text = ui_text_controller.get_selected_photo_text(photo_path.get_file())
	update_ui_visibility()

func update_ui_visibility() -> void:
	var should_show_gallery: bool = (state == "placing" or state == "narrating") and selected_photo_path.is_empty()
	gallery_panel.visible = should_show_gallery
	submit_button.visible = state == "placing" and selected_photo_path != ""

func _on_submit_pressed() -> void:
	if state == "placing":
		place_hidden_photo()

func show_narrative() -> void:
	narrative_index = 0
	narrative_timer = 2.5
	update_narrative()

func update_narrative() -> void:
	narrative_label.text = narrative_lines[narrative_index % narrative_lines.size()]
	narrative_index += 1
	narrative_timer = 2.5

func advance_narrative() -> void:
	if narrative_index < narrative_lines.size():
		update_narrative()
	else:
		narrative_label.text = ""
		state = "placing"

func show_final_scores() -> void:
	state = "finished"
	final_overlay.visible = true
	winner_label.text = ui_text_controller.get_winner_text(scores)
	winner_label.modulate = Color(0.2, 0.85, 0.2, 1.0)
	final_scores_label.text = ui_text_controller.get_final_scores_text(scores)
	rematch_button.text = ui_text_controller.get_rematch_text()
	menu_button.text = ui_text_controller.get_menu_text()
	exit_button.text = ui_text_controller.get_exit_text()

func _on_rematch_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func register_input_actions() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "opacity_down", "opacity_up", "scale_up", "scale_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for action in ["move_up", "move_down", "move_left", "move_right", "opacity_down", "opacity_up", "scale_up", "scale_down"]:
		var key: int = GameSettings.keybinds[action]
		var event: InputEventKey = InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action, event)
	if not InputMap.has_action("select"):
		InputMap.add_action("select")
	var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("select", mouse_event)

func load_assets() -> void:
	background_paths = []
	photo_paths = []
	var dir = DirAccess.open("res://Backgrounds")
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg") or file_name.ends_with(".webp"):
				background_paths.append("res://Backgrounds/%s" % file_name)
	var photo_dir = DirAccess.open("res://Photos")
	if photo_dir:
		for file_name in photo_dir.get_files():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg") or file_name.ends_with(".webp"):
				photo_paths.append("res://Photos/%s" % file_name)
	if background_paths.is_empty():
		background_paths.append("res://icon.svg")
	if photo_paths.is_empty():
		photo_paths.append("res://icon.svg")
