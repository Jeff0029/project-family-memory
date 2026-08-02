extends Node
class_name CalculateScoring

var gameplay_controller: Node2D

func initialize(controller: Node2D) -> void:
	gameplay_controller = controller

func calculate_score() -> int:
	var opacity_percent: float = remap(clamp(gameplay_controller.hidden_photo.modulate.a, gameplay_controller.min_opacity, gameplay_controller.max_opacity), gameplay_controller.min_opacity, gameplay_controller.max_opacity, 0.5, 1.0)
	var scale_percent: float = get_scale_percent_for_score()
	var time_percent: float = clamp(gameplay_controller.search_timer / float(gameplay_controller.gameplay_timer), 0.0, 1.0)
	return int(round(gameplay_controller.max_score * opacity_percent * scale_percent * time_percent))

func get_scale_percent_for_score() -> float:
	var min_scale_limit: float = gameplay_controller.hidden_photo_controller.get_min_scale_limit()
	var max_scale_limit: float = gameplay_controller.hidden_photo_controller.get_max_scale_limit()
	if max_scale_limit < min_scale_limit:
		var swap: float = min_scale_limit
		min_scale_limit = max_scale_limit
		max_scale_limit = swap
	if is_equal_approx(min_scale_limit, max_scale_limit):
		return 1.0
	return remap(gameplay_controller.hidden_photo.scale.x, min_scale_limit, max_scale_limit, 0.5, 1.0)
