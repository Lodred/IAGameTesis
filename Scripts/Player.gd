extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var hitbox = $PlayerHitbox

@export var health: int = 100
@export var speed: int = 50
@export var damage: int = 5

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO

@export var is_attacking = false
@export var enemy_in_range = false
@export var attack_cooldown = false
@export var is_alive = true

func _ready():
	# Ensure AnimationTree is active
	$AnimationTree.active = true

func _physics_process(delta):
	if is_alive == true:
		if health <= 0:
			health = 0
			is_alive = false
			print("Player has been killed")
			self.queue_free()
			#Death Animation
			#End Screen
		if is_attacking == false:
			# Movement
			move_player()
		# Attack
		if Input.is_action_just_pressed("Attack") and attack_cooldown == false:
			attack()

func move_player():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")

	velocity = input_vector.normalized() * speed

	if input_vector == Vector2.ZERO:
		$AnimationTree.get("parameters/playback").travel("Idle")
	else:
		$AnimationTree.get("parameters/playback").travel("Run")
		$AnimationTree.set("parameters/Idle/blend_position", input_vector)
		$AnimationTree.set("parameters/Run/blend_position", input_vector)
		$AnimationTree.set("parameters/Stab_Attack/blend_position", input_vector)

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
		if otherbody.has_method("enemy_attack") and otherbody.has_method("enemy"):
			otherbody.enemy_attack(damage)

func finish_attack():
	is_attacking = false

func enemy_attack(damage):
	if enemy_in_range:
		health = health - damage
		print("Player health " +str(health))
	
func player():
	pass

func _on_attack_cooldown_timeout():
	attack_cooldown = false
