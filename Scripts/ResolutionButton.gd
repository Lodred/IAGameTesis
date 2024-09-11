extends OptionButton

const RESOLUTION_DICTIONARY: Dictionary = {
	"1152 x 648" : Vector2i(1152, 648),
	"1280 x 720" : Vector2i(1280, 720),
	"1920 x 1080" : Vector2i(1920, 1080),
}

func _ready():
	$".".item_selected.connect(on_resolution_selected)
	add_resolution_items()

func add_resolution_items() -> void:
	for resolution_size_text in RESOLUTION_DICTIONARY:
		$".".add_item(resolution_size_text)
		

func on_resolution_selected(index : int) -> void:
	DisplayServer.window_set_size(RESOLUTION_DICTIONARY.values()[index])
	centre_window()

func centre_window():

	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)
