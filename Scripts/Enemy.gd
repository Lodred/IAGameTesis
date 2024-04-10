extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree

@export var Health: int = 4
@export var Speed: int = 40
@export var AttackPower = 1
@export var Knockback_STR = 100

@export var Friction: float = 0.15
@export var Acceleration: int = 40

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO
var move_direction = Vector2()
var is_moving = false
var see_player = false

func _ready():
	animTree.active = true
	
func _physics_process(delta):
	if see_player == true:
		var player = get_parent().get_node("Player")
		accelerate_towards_point(player, delta)
		move_and_slide()
	else:
		animTree.get("parameters/playback").travel("Idle")
	
	knockback_direction = move_direction
	knockback = knockback.move_toward(Vector2.ZERO, 200*delta)
	
func accelerate_towards_point(point, delta):
	var movement = move_direction * Speed
	move_direction = (point.position - position).normalized()
	velocity = movement + (knockback * 2)
	velocity = velocity.move_toward(move_direction * Speed, 200 * delta)
	animTree.get("parameters/playback").travel("Run")
	animTree.set("parameters/Idle/blend_position", move_direction)
	animTree.set("parameters/Run/blend_position", move_direction)
	
func _on_player_detection_area_body_entered(body):
	if body.name == "Player":
		see_player = true

func _on_player_detection_area_exited(body):
	if body.name == "Player":
		see_player = false
