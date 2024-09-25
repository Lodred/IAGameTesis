extends Control

@export var dialogues = []  # This will be set dynamically by the enemy script
@export var current_index = 0

# Nodes references
@onready var character_name_label = $Dialogue/MenuBox/HBoxContainer/VBoxContainer/Name
@onready var character_sprite = $Dialogue/MenuBox/HBoxContainer/Portrait
@onready var dialogue_text = $Dialogue/MenuBox/HBoxContainer/VBoxContainer/Text
@onready var dialogue_panel = $Dialogue
@onready var player = $"../Player"

var callback_node = null  # The node that will receive the callback
var callback_method = ""  # The method that will be called

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	dialogue_panel.visible = false  # Hide the dialogue panel when the scene is loaded

# Start the dialogue process, set the callback for when the dialogue ends
func start_dialogue(node, method):
	dialogues = State.current_dialogues  # Fetch the current dialogues from the global State
	current_index = 0
	callback_node = node
	callback_method = method
	dialogue_panel.visible = true  # Show the dialogue panel when a new dialogue starts
	
	# Disable player movement when dialogue starts
	player.disable_movement()
	
	display_dialogue()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):  # Use an action to check for the left mouse click or Enter
		advance_dialogue()

# Display current dialogue information
func display_dialogue():
	if current_index < dialogues.size():
		var current_dialogue = dialogues[current_index]
		
		# Update dialogue text, character name, and character sprite
		dialogue_text.text = current_dialogue["text"]
		character_name_label.text = current_dialogue["character_name"]
		
		var sprite_path = current_dialogue["sprite"]
		if character_sprite.texture and character_sprite.texture.resource_path != sprite_path:
			character_sprite.texture = load(sprite_path)  # Load the new character sprite
		
	else:
		dialogue_panel.visible = false  # Hide the dialogue panel when done
		finish_dialogue()

# Advance to the next dialogue entry
func advance_dialogue():
	current_index += 1
	display_dialogue()

# When the dialogue finishes, call the callback method on the node
func finish_dialogue():
	if callback_node and callback_method != "":
		callback_node.call(callback_method)  # Call the method (e.g., to transition to combat)
	
	# Re-enable player movement when the dialogue ends
	player.enable_movement()
