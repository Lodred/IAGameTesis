extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var _focus = $Focus
@onready var progress_bar = $ProgressBar

var combat_node

var speed: int = 10
var accumulated_speed = 0
var max_health = 10

var current_health: float = State.Player_max_health:
	set(value):
		current_health = State.Player_current_health
		if current_health <= 0:
			is_alive = false
			$AnimationTree.get("parameters/playback").travel("Dead")
			#self.queue_free()
		else:
			_gethurt()

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO

@export var is_attacking = false
@export var is_hurting = false
@export var is_alive = true

func _ready():
	combat_node = get_node("/root/Combat")
	speed = State.Player_speed
	# Ensure AnimationTree is active
	$AnimationTree.active = true

func _physics_process(delta):
	if is_alive == true:
		if is_attacking == false and is_hurting == false:
			# Movement
			move_player()

func move_player():
	$AnimationTree.get("parameters/playback").travel("Idle_Left")

func attack():
	if is_alive == true:
		is_attacking = true
		# Trigger attack animation
		$AnimationTree.get("parameters/playback").travel("Stab_Left")

func finish_attack():
	is_attacking = false

func finish_hurt():
	is_hurting = false

func player():
	pass

func _gethurt():
	is_hurting = true
	$AnimationTree.get("parameters/playback").travel("Hurt")
 
func focus():
	_focus.show()
 
func unfocus():
	_focus.hide()
 
func remove_turn(value):
	await combat_node.remove_from_turn_queue(value)

func die():
	is_alive = false
	State.Player_alive = false
	$AnimationTree.get("parameters/playback").travel("Dead")

func take_damage(damage, attacker_name, target_name):
	if State.Player_current_health - damage <= 0:
		combat_node.display_text("Player was defeated!")
		die()
		State.Player_current_health = 0
		remove_turn("Player")
		combat_node.check_for_allies()
		#If the array is empty the battle is Lost
		#if enemies.size() <= 0:
			#enemies_left = false
			#if combat_node and combat_node.has_method("win_battle"):
				#combat_node.win_battle()
	else:
		State.Player_current_health = State.Player_current_health - damage
		combat_node.display_text(attacker_name + " attacks " + target_name + " for " + str(damage) + " damage!")
		_gethurt()
	pass
