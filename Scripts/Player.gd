extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree

@export var Speed: int = 50
@export var Friction: float = 0.15
@export var Acceleration: int = 40

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO
var is_moving = false
@export var is_attacking = false
var is_death = false

func _ready():
	# Ensure AnimationTree is active
	$AnimationTree.active = true

func _physics_process(delta):
	if not is_death:
		if is_attacking == false:
			# Movement
			move_player()
		# Attack
		if Input.is_action_just_pressed("Attack"):
			is_attacking = true
			attack()

func move_player():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")

	velocity = input_vector.normalized() * Speed

	if input_vector == Vector2.ZERO:
		$AnimationTree.get("parameters/playback").travel("Idle")
	else:
		$AnimationTree.get("parameters/playback").travel("Run")
		$AnimationTree.set("parameters/Idle/blend_position", input_vector)
		$AnimationTree.set("parameters/Run/blend_position", input_vector)
		$AnimationTree.set("parameters/Stab_Attack/blend_position", input_vector)

	move_and_slide()

func attack():
	# Trigger attack animation
	$AnimationTree.get("parameters/playback").travel("Stab_Attack")
	# Apply attack to nearby hitboxes
	var attack_area = $Marker2D/AttackHitbox

func Finish_Attack():
	is_attacking = false

# Signal for taking damage
func _on_HitboxComponent_health_changed(new_health):
	if new_health <= 0:
		die()

# Handle death
func die():
	is_death = true
	# Play death animation or perform other death-related actions
	pass
