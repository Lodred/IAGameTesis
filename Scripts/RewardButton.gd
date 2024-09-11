extends OptionButton

const REWARD_DICTIONARY: Dictionary = {
	"Mixed" : "mixed",
	"Reward" : "reward",
	"Penalty" : "penalty",
}

var selected_reward_type: String = "mixed"  # Default value

func _ready():
	$".".item_selected.connect(on_reward_selected)
	add_reward_items()

func add_reward_items() -> void:
	for reward_size_text in REWARD_DICTIONARY:
		$".".add_item(reward_size_text)

func on_reward_selected(index : int) -> void:
	var reward_text = $".".get_item_text(index)
	selected_reward_type = REWARD_DICTIONARY[reward_text]

# Function to return the selected reward type
func get_selected_reward_type() -> String:
	return selected_reward_type

