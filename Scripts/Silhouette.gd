extends Sprite2D

@onready var _silhouette_sprite: Sprite2D = $Silhouette

func _ready() -> void:
	_silhouette_sprite.texture = texture
	_silhouette_sprite.offset = offset
	_silhouette_sprite.flip_h = flip_h
	_silhouette_sprite.hframes = hframes
	_silhouette_sprite.vframes = vframes
	_silhouette_sprite.frame = frame


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _set(property: StringName, value: Variant) -> bool:
	if is_instance_valid(_silhouette_sprite):
		match property:
			"texture":
				_silhouette_sprite.texture = value
			"offset":
				_silhouette_sprite.offset = value
			"flip_h":
				_silhouette_sprite.flip_h = value
			"hframes":
				_silhouette_sprite.hframes = value
			"vframes":
				_silhouette_sprite.vframes = value
			"frame":
				_silhouette_sprite.frame = value
	return false
