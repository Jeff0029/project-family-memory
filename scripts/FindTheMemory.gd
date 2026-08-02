extends Node
class_name FindTheMemory

var gameplay_controller: Node2D

func initialize(controller: Node2D) -> void:
	gameplay_controller = controller

func start_search_transition() -> void:
	gameplay_controller.fade_overlay.visible = true
	gameplay_controller.fade_overlay.color = Color(0, 0, 0, 0)

	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(gameplay_controller.fade_overlay, "color", Color(0, 0, 0, 1), gameplay_controller.fade_overlay_duration_seconds)
	await fade_in_tween.finished

	var hold_tween: Tween = create_tween()
	hold_tween.tween_interval(gameplay_controller.fade_overlay_on_duration)
	await hold_tween.finished

	var fade_out_tween: Tween = create_tween()
	fade_out_tween.tween_property(gameplay_controller.fade_overlay, "color", Color(0, 0, 0, 0), gameplay_controller.fade_overlay_duration_seconds)
	await fade_out_tween.finished
	gameplay_controller.fade_overlay.visible = false

func fit_camera_to_background() -> void:
	await get_tree().process_frame
	var viewport_size: Vector2 = gameplay_controller.camera_2d.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	var target_center: Vector2 = gameplay_controller.get_camera_target_position()
	var target_size: Vector2 = gameplay_controller.backdrop.size
	if gameplay_controller.background_sprite.texture != null:
		var sprite_size: Vector2 = gameplay_controller.background_sprite.texture.get_size() * gameplay_controller.background_sprite.scale
		target_size = sprite_size

	var padding_factor: float = max(1.0 + gameplay_controller.zoom_padding * 1.4, 1.0)
	var width_zoom: float = target_size.x / max(viewport_size.x * padding_factor, 1.0)
	var height_zoom: float = target_size.y / max(viewport_size.y * padding_factor, 1.0)
	var final_zoom: float = max(width_zoom, height_zoom)

	var zoom_vector: Vector2 = Vector2.ONE * clamp(final_zoom, gameplay_controller.camera_zoom_min, gameplay_controller.camera_zoom_max)
	gameplay_controller.camera_2d.make_current()
	gameplay_controller.camera_2d.zoom = zoom_vector
	gameplay_controller.camera_2d.global_position = target_center - (viewport_size * 0.5) / zoom_vector
