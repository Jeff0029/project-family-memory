extends Node
class_name HiddenPhotoController

var gameplay_controller: Node2D

func initialize(controller: Node2D) -> void:
	gameplay_controller = controller

func apply_photo_scale_from_texture() -> void:
	if gameplay_controller.current_photo_texture == null:
		return
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	hidden_photo.scale = Vector2.ONE * get_max_scale_limit()
	sync_hidden_photo_button()

func update_photo_rotation_from_mouse(mouse_position: Vector2) -> void:
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	var mouse_delta_from_center: Vector2 = mouse_position - hidden_photo.global_position
	if mouse_delta_from_center.length_squared() > 0.0001:
		gameplay_controller.current_photo_rotation = mouse_delta_from_center.angle()
		hidden_photo.rotation = gameplay_controller.current_photo_rotation
	sync_hidden_photo_button()

func update_photo_position_from_mouse(current_mouse_position: Vector2, last_mouse_position: Vector2) -> void:
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	var delta: Vector2 = current_mouse_position - last_mouse_position
	hidden_photo.position += delta
	gameplay_controller.last_mouse_position = current_mouse_position
	var half_size: Vector2 = hidden_photo.texture.get_size() * hidden_photo.scale * 0.5
	var bounds: Rect2 = Rect2(gameplay_controller.backdrop.position + Vector2(80, 80), gameplay_controller.backdrop.size - Vector2(160, 160))
	hidden_photo.position.x = clamp(hidden_photo.position.x, bounds.position.x + half_size.x, bounds.end.x - half_size.x)
	hidden_photo.position.y = clamp(hidden_photo.position.y, bounds.position.y + half_size.y, bounds.end.y - half_size.y)
	sync_hidden_photo_button()

func adjust_hidden_photo_scale(delta: float) -> void:
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	var current_scale: float = hidden_photo.scale.x
	var target_scale: float = clamp(current_scale + delta, get_min_scale_limit(), get_max_scale_limit())
	if is_equal_approx(current_scale, target_scale):
		return
	if gameplay_controller.zoom_tween != null:
		gameplay_controller.zoom_tween.kill()
	gameplay_controller.zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	gameplay_controller.zoom_tween.tween_property(hidden_photo, "scale", Vector2.ONE * target_scale, 0.12)
	gameplay_controller.zoom_tween.finished.connect(sync_hidden_photo_button)

func get_min_scale_limit() -> float:
	if gameplay_controller.current_photo_texture == null:
		return 0.001
	var texture_size: Vector2 = gameplay_controller.current_photo_texture.get_size()
	var texture_area: float = max(texture_size.x, 1.0) * max(texture_size.y, 1.0)
	var min_scale: float = sqrt(float(gameplay_controller.min_pixels_squared) / max(texture_area, 1.0))
	return clamp(min_scale, 0.001, gameplay_controller.starting_hidden_photo_scale)

func get_max_scale_limit() -> float:
	return clamp(gameplay_controller.starting_hidden_photo_scale, get_min_scale_limit(), 1.0)

func apply_saved_transform() -> void:
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	hidden_photo.rotation = gameplay_controller.placement_rotation
	gameplay_controller.current_photo_rotation = gameplay_controller.placement_rotation
	hidden_photo.position = gameplay_controller.placement_position
	sync_hidden_photo_button()

func sync_hidden_photo_button() -> void:
	var hidden_photo: Sprite2D = gameplay_controller.hidden_photo
	var hidden_photo_button: TextureButton = gameplay_controller.hidden_photo_button
	if hidden_photo_button == null:
		return
	hidden_photo_button.texture_normal = null
	hidden_photo_button.size = hidden_photo.texture.get_size() * hidden_photo.scale
	hidden_photo_button.position = hidden_photo.position - (hidden_photo.texture.get_size() * hidden_photo.scale * 0.5)
	hidden_photo_button.rotation = hidden_photo.rotation
	hidden_photo_button.scale = hidden_photo.scale
	hidden_photo_button.pivot_offset = hidden_photo.texture.get_size() * 0.5
	if gameplay_controller.hidden_photo_area != null and gameplay_controller.hidden_photo_hit_shape != null:
		gameplay_controller.hidden_photo_area.position = hidden_photo.position
		gameplay_controller.hidden_photo_area.rotation = hidden_photo.rotation
		gameplay_controller.hidden_photo_area.scale = hidden_photo.scale
		var hit_shape: RectangleShape2D = gameplay_controller.hidden_photo_hit_shape.shape
		hit_shape.extents = hidden_photo.texture.get_size() * hidden_photo.scale * 0.5
		gameplay_controller.hidden_photo_area.visible = hidden_photo.visible
		gameplay_controller.hidden_photo_area.monitoring = hidden_photo.visible
		gameplay_controller.hidden_photo_area.monitorable = hidden_photo.visible
	if hidden_photo.visible:
		hidden_photo_button.visible = true
	else:
		hidden_photo_button.visible = false
