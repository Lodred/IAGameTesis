extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var hitbox = $EnemyHitbox

@export var id: int = 0
var health: int = 25
var speed: int = 40

#Delete all non related to movement stats
@export var Enemies: Array[Resource] = []
@export var dialogues = [
	{"text": "Who goes there?", "character_name": "Guard", "sprite": "res://guard_sprite.png"},
	{"text": "You cannot pass!", "character_name": "Guard", "sprite": "res://guard_sprite.png"},
	{"text": "Prepare to fight!", "character_name": "Guard", "sprite": "res://guard_sprite.png"}
]  # Default dialogues (can be customized per enemy instance)

@export var initial_direction = Vector2(0, 1) # Default facing down

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO
var move_direction = Vector2()
var is_moving = false
var see_player = false
var dialogue_started = false

var is_attacking = false
var enemy_in_range = false
var attack_cooldown = false

func _ready():
	animTree.active = true
	# Set initial direction
	set_initial_facing_direction(initial_direction)

func _physics_process(delta):
	await get_tree().create_timer(0.8).timeout
	if enemy_in_range and not attack_cooldown:
		attack()
	if not is_attacking:
		if see_player and not dialogue_started:
			start_dialogue()  # Start the dialogue when the player is seen
		else:
			animTree.get("parameters/playback").travel("Idle")
		knockback_direction = move_direction
		knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	
func accelerate_towards_point(point, delta):
	var movement = move_direction * speed
	move_direction = (point.position - position).normalized()
	velocity = movement + (knockback * 2)
	velocity = velocity.move_toward(move_direction * speed, 200 * delta)
	animTree.get("parameters/playback").travel("Run")
	animTree.set("parameters/Idle/blend_position", move_direction)
	animTree.set("parameters/Run/blend_position", move_direction)
	animTree.set("parameters/Stab_Attack/blend_position", move_direction)
	
func _on_player_detection_area_body_entered(body):
	if body.name == "Player":
		see_player = true

func _on_player_detection_area_exited(body):
	if body.name == "Player":
		see_player = false


func _on_enemy_hitbox_body_entered(body):
	if body.has_method("player") or body.has_method("ally"):
		enemy_in_range = true


func _on_enemy_hitbox_body_exited(body):
	var enemies_in_range = 0
	for otherbody in hitbox.get_overlapping_bodies():
		if otherbody.has_method("player") or otherbody.has_method("ally"):
			enemies_in_range = enemies_in_range + 1
	if enemies_in_range == 0:
		if body.has_method("player") or body.has_method("ally"):
			enemy_in_range = false
	else:
		pass

func attack():
	is_attacking = true
	attack_cooldown = true
	$AttackCooldown.start()
	# Trigger attack animation
	$AnimationTree.get("parameters/playback").travel("Stab_Attack")
	for otherbody in hitbox.get_overlapping_bodies():
		if (otherbody.has_method("player") or otherbody.has_method("ally")):
			await get_tree().create_timer(0.8).timeout
			State.Enemies = Enemies
			State.player_position = otherbody.position
			State.enemy_to_remove_id.append(id)
			get_tree().change_scene_to_file("res://Scenes/Combat.tscn")
			#otherbody.enemy_attack(damage)

# Start the dialogue for this specific enemy
func start_dialogue():
	dialogue_started = true  # Ensure this only triggers once
	State.current_dialogues = dialogues  # Pass the current enemy's dialogues to the global State
	var dialogue_manager = get_tree().root.get_node("World/Dialogue_control")  # Ensure you get the right path
	dialogue_manager.start_dialogue(self, "on_dialogue_finished")

# This function will be called when the dialogue finishes
func on_dialogue_finished():
	var player = get_parent().get_node("Player")
	proceed_to_combat(player)

# Transition to combat after dialogue ends
func proceed_to_combat(player):
	await get_tree().create_timer(0.1).timeout
	State.Enemies = Enemies
	State.player_position = player.position
	State.enemy_to_remove_id.append(id)
	get_tree().change_scene_to_file("res://Scenes/Combat.tscn")

func finish_attack():
	is_attacking = false

func _on_attack_cooldown_timeout():
	attack_cooldown = false

func enemy():
	pass

func set_initial_facing_direction(direction: Vector2):
	# Set the blend position for Idle, Run, and other animations
	animTree.set("parameters/Idle/blend_position", direction)
	animTree.set("parameters/Run/blend_position", direction)
	animTree.set("parameters/Stab_Attack/blend_position", direction)
	move_direction = direction
