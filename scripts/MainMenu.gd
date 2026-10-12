extends Control

const UI_SELECT_DELAY_SECONDS: float = 0.08

@onready var title_label: Label = $VBoxContainer/Title
@onready var subtitle_label: Label = $VBoxContainer/Subtitle
const TIME_OPTIONS: Array[Dictionary] = [
	{"seconds": 30, "key": "time_30s"},
	{"seconds": 60, "key": "time_1m"},
	{"seconds": 120, "key": "time_2m"},
	{"seconds": 180, "key": "time_3m"},
	{"seconds": 300, "key": "time_5m"},
]
const ROUND_OPTIONS: Array[int] = [2, 4, 6, 8, 10]

@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var time_option: OptionButton = $VBoxContainer/TimeOption
@onready var rounds_label: Label = $VBoxContainer/RoundsLabel
@onready var rounds_option: OptionButton = $VBoxContainer/RoundsOption
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

var main_menu_music_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}

func _ready() -> void:
	apply_text()
	load_sfx_assets()
	start_main_menu_music()
	time_option.item_selected.connect(_on_time_selected)
	rounds_option.item_selected.connect(_on_rounds_selected)
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func apply_text() -> void:
	title_label.text = GameSettings.get_text("title")
	subtitle_label.text = GameSettings.get_text("subtitle")
	start_button.text = GameSettings.get_text("start")
	settings_button.text = GameSettings.get_text("settings")
	exit_button.text = GameSettings.get_text("exit")
	time_label.text = GameSettings.get_text("time_per_round")
	rounds_label.text = GameSettings.get_text("number_of_rounds")
	time_option.clear()
	for i in TIME_OPTIONS.size():
		time_option.add_item(GameSettings.get_text(TIME_OPTIONS[i]["key"]))
		if TIME_OPTIONS[i]["seconds"] == GameSettings.round_time_seconds:
			time_option.select(i)
	rounds_option.clear()
	for i in ROUND_OPTIONS.size():
		rounds_option.add_item(str(ROUND_OPTIONS[i]))
		if ROUND_OPTIONS[i] == GameSettings.round_count:
			rounds_option.select(i)

func _on_time_selected(index: int) -> void:
	GameSettings.round_time_seconds = TIME_OPTIONS[index]["seconds"]

func _on_rounds_selected(index: int) -> void:
	GameSettings.round_count = ROUND_OPTIONS[index]

func _on_start_pressed() -> void:
	await play_ui_select_feedback()
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_settings_pressed() -> void:
	await play_ui_select_feedback()
	get_tree().change_scene_to_file("res://Settings.tscn")

func _on_exit_pressed() -> void:
	await play_ui_select_feedback()
	get_tree().quit()

func start_main_menu_music() -> void:
	var stream: AudioStream = get_sfx_stream("MainMenu")
	set_stream_looping(stream)
	main_menu_music_player = AudioStreamPlayer.new()
	main_menu_music_player.stream = stream
	main_menu_music_player.bus = &"Master"
	main_menu_music_player.volume_db = linear_volume_to_db(GameSettings.master_volume * GameSettings.background_volume)
	add_child(main_menu_music_player)
	main_menu_music_player.play()

func play_ui_select_feedback() -> void:
	play_sfx(get_sfx_stream("UIMenuSelect"), GameSettings.ui_volume)
	await get_tree().create_timer(UI_SELECT_DELAY_SECONDS).timeout

func play_sfx(stream: AudioStream, channel_volume: float) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"Master"
	player.volume_db = linear_volume_to_db(GameSettings.master_volume * channel_volume)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func linear_volume_to_db(volume_linear: float) -> float:
	var clamped_volume: float = clamp(volume_linear, 0.0, 1.0)
	if clamped_volume <= 0.0001:
		return -80.0
	return linear_to_db(clamped_volume)

func set_stream_looping(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

func load_sfx_assets() -> void:
	sfx_streams.clear()
	for entry in ResourceLoader.list_directory("res://sfx"):
		if entry.ends_with("/"):
			continue
		var extension: String = entry.get_extension().to_lower()
		if extension not in ["mp3", "ogg", "wav"]:
			continue
		var resource: Resource = ResourceLoader.load("res://sfx/%s" % entry)
		if resource is AudioStream:
			var stream: AudioStream = resource
			if entry.get_basename() == "MainMenu":
				set_stream_looping(stream)
			sfx_streams[entry.get_basename()] = stream

func get_sfx_stream(base_name: String) -> AudioStream:
	return sfx_streams.get(base_name, null)
