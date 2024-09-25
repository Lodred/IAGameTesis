extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var hitbox = $PlayerHitbox
@onready var playerWalkingAudioStream = $AudioStreamPlayer_Walking

@export var speed: int = 50

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO

@export var is_attacking = false
@export var enemy_in_range = false
@export var attack_cooldown = false
var can_move = true

func _ready():
	# Ensure AnimationTree is active
	$AnimationTree.active = true

func _physics_process(delta):
	# Movement
	if is_attacking == false and can_move:
		move_player()
	# Attack
	if Input.is_action_just_pressed("Attack") and attack_cooldown == false:
		pass
		#attack()

func move_player():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")

	velocity = input_vector.normalized() * speed

	if input_vector == Vector2.ZERO:
		$AnimationTree.get("parameters/playback").travel("Idle")
		playerWalkingAudioStream.stop()
	else:
		$AnimationTree.get("parameters/playback").travel("Run")
		$AnimationTree.set("parameters/Idle/blend_position", input_vector)
		$AnimationTree.set("parameters/Run/blend_position", input_vector)
		$AnimationTree.set("parameters/Stab_Attack/blend_position", input_vector)
		
		if !playerWalkingAudioStream.playing:
			playerWalkingAudioStream.play()

	move_and_slide()

func _on_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_in_range = true


func _on_hitbox_body_exited(body):
	var enemies_in_range = 0
	for otherbody in hitbox.get_overlapping_bodies():
		if otherbody.has_method("enemy"):
			enemies_in_range = enemies_in_range + 1
	if enemies_in_range == 0:
		if body.has_method("enemy"):
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
		if otherbody.has_method("enemy"):
			await get_tree().create_timer(0.8).timeout
			State.Enemies = otherbody.Enemies
			State.player_position = self.position
			State.enemy_to_remove_id.append(otherbody.id)
			get_tree().change_scene_to_file("res://Scenes/Combat.tscn")
			#otherbody.enemy_attack(damage)

func finish_attack():
	is_attacking = false

func player():
	pass

func _on_attack_cooldown_timeout():
	attack_cooldown = false

# Call this method to disable movement when dialogue starts
func disable_movement():
	can_move = false
	$AnimationTree.get("parameters/playback").travel("Idle")
	playerWalkingAudioStream.stop()

# Call this method to enable movement when dialogue ends
func enable_movement():
	can_move = true
