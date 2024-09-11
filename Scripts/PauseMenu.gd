extends CanvasLayer

@onready var World = $".."
@onready var Audio = $AudioBox

# Called when the node enters the scene tree for the first time.
func _ready():
	Audio.visible = false

func _on_resume_pressed():
	World.is_paused = !World.is_paused # Toggle pause state
	World.pause(false)

func _on_settings_pressed():
	Audio.visible = true

func _on_save_audio_pressed():
	Audio.visible = false

func _on_exit_pressed():
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
