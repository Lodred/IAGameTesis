extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var hitbox = $EnemyHitbox

@export var health: int = 25
@export var speed: int = 40
@export var damage: int = 5

var knockback_direction = Vector2.ZERO
var knockback = Vector2.ZERO
var move_direction = Vector2()
var is_moving = false
var see_player = false

@export var is_attacking = false
@export var enemy_in_range = false
@export var attack_cooldown = false
@export var is_alive = true

func _ready():
	animTree.active = true
	
func _physics_process(delta):
	if is_alive:
		if health <= 0:
			health = 0
			is_alive = false
			print("Enemy has been killed")
			self.queue_free()
		if enemy_in_range == true and attack_cooldown == false:
				attack()
		if is_attacking == false:
			if see_player == true:
				var player = get_parent().get_node("Player")
				accelerate_towards_point(player, delta)
				move_and_slide()
			else:
				animTree.get("parameters/playback").travel("Idle")
		
		knockback_direction = move_direction
		knockback = knockback.move_toward(Vector2.ZERO, 200*delta)
	
func accelerate_towards_point(point, delta):
	var movement = move_direction * speed
	move_direction = (point.position - position).normalized()
	velocity = movement + (knockback * 2)
	velocity = velocity.move_toward(move_direction * speed, 200 * delta)
	animTree.get("parameters/playback").travel("Run")
	animTree.set("parameters/Idle/blend_position", move_direction)
	animTree.set("parameters/Run/blend_position", move_direction)
	
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
	for otherbody in hitbox.get_overlapping_bodies():
		if otherbody.has_method("enemy_attack") and (otherbody.has_method("player") or otherbody.has_method("ally")):
			otherbody.enemy_attack(damage)

func enemy_attack(damage):
	if enemy_in_range:
		health = health - damage
		print("Enemy health " + str(health))

func _on_attack_cooldown_timeout():
	is_attacking = false
	attack_cooldown = false

func enemy():
	pass
	

#func _physics_process(delta):
	#if enemy_in_range == true and attack_cooldown == false:
	#		attack()
	#if is_attacking == false:
	#if see_player == true:
	#	var player = get_parent().get_node("Player")
	#	accelerate_towards_point(player, delta)
	#	move_and_slide()
	#else:
	#	animTree.get("parameters/playback").travel("Idle")
	#
	#knockback_direction = move_direction
	#knockback = knockback.move_toward(Vector2.ZERO, 200*delta)
