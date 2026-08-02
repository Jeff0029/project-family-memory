extends Node
class_name UITextController

var gameplay_controller: Node2D

func initialize(controller: Node2D) -> void:
	gameplay_controller = controller

func get_round_text(round_number: int) -> String:
	return "%s %d" % [GameSettings.get_text("round"), round_number]

func get_status_place_text() -> String:
	return GameSettings.get_text("status_place")

func get_status_search_text() -> String:
	return GameSettings.get_text("status_search")

func get_searching_text() -> String:
	return GameSettings.get_text("searching")

func get_placing_text() -> String:
	return GameSettings.get_text("placing")

func get_selected_photo_text(photo_name: String) -> String:
	return "Selected: %s" % photo_name

func get_choose_memory_text() -> String:
	return GameSettings.get_text("choose_memory")

func get_final_message_text(score: int) -> String:
	return "%s: %d" % [GameSettings.get_text("final_message"), score]

func get_score_label_text(scores: Array[int]) -> String:
	return "Joueur 1 : %d  |  Joueur 2 : %d" % [scores[0], scores[1]]

func get_winner_text(scores: Array[int]) -> String:
	var winner_index: int = 0
	if scores[1] > scores[0]:
		winner_index = 1
	return "%s: %s" % [GameSettings.get_text("winner"), "Player %d" % (winner_index + 1)]

func get_final_scores_text(scores: Array[int]) -> String:
	return "Joueur 1 : %d\nJoueur 2 : %d" % [scores[0], scores[1]]

func get_rematch_text() -> String:
	return GameSettings.get_text("rematch")

func get_menu_text() -> String:
	return GameSettings.get_text("menu")

func get_exit_text() -> String:
	return GameSettings.get_text("exit_game")
