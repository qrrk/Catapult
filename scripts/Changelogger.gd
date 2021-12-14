extends Node


onready var _settings = $"/root/SettingsManager"

# Called when the node enters the scene tree for the first time.
func _ready():
	var game = _settings.read("game")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
