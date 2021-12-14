extends Node


onready var _settings = $"/root/SettingsManager"

# Called when the node enters the scene tree for the first time.
func _ready():
	var game = _settings.read("game")
	OS.set_window_title("Recent changes made to")
	_log.text = ""
	
	var welcome_msg = "Welcome to Catapult!"
	if _settings.read("print_tips_of_the_day"):
		welcome_msg += "\n\n[u]Tip of the day:[/u]\n" + _totd.get_tip() + "\n"
	print_msg(welcome_msg)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
