extends Node

var master_volume: float = 1.0
var background_volume: float = 0.8
var ui_volume: float = 0.8
var language: String = "Français"

var keybinds: Dictionary = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"rotate": KEY_R,
	"opacity_down": KEY_E,
	"opacity_up": KEY_Q,
	"scale_up": KEY_X,
	"scale_down": KEY_Z,
	"select": MOUSE_BUTTON_LEFT,
}

const TEXT: Dictionary = {
	"English": {
		"title": "Family Memory Hunt",
		"subtitle": "A wedding tribute for 40 years of love",
		"start": "Start Game",
		"settings": "Settings",
		"exit": "Exit",
		"back": "Back",
		"volume": "Volume",
		"master": "Master",
		"background": "Background",
		"music": "Music",
		"ui": "UI",
		"language": "Language",
		"round": "Round",
		"status_place": "Place the hidden memory on the wedding backdrop",
		"status_search": "Find the hidden memory",
		"status_results": "Round complete",
		"rematch": "Rematch",
		"menu": "Back to Menu",
		"exit_game": "Exit",
		"winner": "Winner",
		"scores": "Scores",
		"placing": "Place the photo with your mouse, then click to lock it in.",
		"searching": "The screen will black out, then you will search for the hidden memory.",
		"final_message": "The family memory has been found.",
		"choose_memory": "Choose a memory"
	},
	"Français": {
		"title": "Chasse aux souvenirs de famille",
		"subtitle": "Un hommage de mariage pour 40 ans d'amour",
		"start": "Commencer",
		"settings": "Paramètres",
		"exit": "Quitter",
		"back": "Retour",
		"volume": "Volume",
		"master": "Maître",
		"background": "Arrière-plan",
		"music": "Musique",
		"ui": "Interface",
		"language": "Langue",
		"round": "Manche",
		"status_place": "Placez le souvenir caché sur le décor de mariage",
		"status_search": "Trouvez le souvenir caché",
		"status_results": "Manche terminée",
		"rematch": "Rejouer",
		"menu": "Retour au menu",
		"exit_game": "Quitter",
		"winner": "Vainqueur",
		"scores": "Scores",
		"placing": "Placez la photo avec la souris, puis cliquez pour la verrouiller.",
		"searching": "L'écran s'éteindra, puis vous chercherez le souvenir caché.",
		"final_message": "Le souvenir de famille a été trouvé.",
		"choose_memory": "Choisissez un souvenir"
	}
}

func get_text(key: String) -> String:
	var lang = TEXT.get(language, TEXT["English"])
	return lang.get(key, TEXT["English"].get(key, key))
