extends CharacterBody2D
@onready var animated_sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var _focus = $Focus
@onready var progress_bar = $ProgressBar

@export var enemy_name = "Enemy"
@export var max_health = 10
@export var max_damage = 2
@export var min_damage = 1
@export var speed = 1
@export var accumulated_speed = 0

const BaseEnemy = preload("res://Entities/BaseEnemy.gd")
@export var enemy_data: BaseEnemy
 
var current_health: float = max_health:
	set(value):
		current_health = value
		set_health(progress_bar, current_health, max_health)
		if current_health <= 0:
			is_alive = false
			$AnimationTree.get("parameters/playback").travel("Dead")
			#self.queue_free()
		else:
			_gethurt()

var move_direction = Vector2()
var is_moving = false

@export var is_attacking = false
@export var is_hurting = false
@export var is_alive = true

func _ready():
	if enemy_data and enemy_data is BaseEnemy:
		if enemy_data.texture:
			$Sprite/Body.set_texture(enemy_data.texture)
			$ProgressBar
			enemy_name = enemy_data.name
			max_health = enemy_data.max_health
			current_health = max_health
			max_damage = enemy_data.max_damage
			min_damage = enemy_data.min_damage
			speed = enemy_data.speed
			set_health(progress_bar, current_health, max_health)
		else:
			print("Enemy data does not have a texture.")
	animTree.active = true
	
func _physics_process(delta):
	if is_alive:
		#if enemy_in_range == true and is_attacking == false:
				#attack()
		if is_attacking == false and is_hurting == false:
			$AnimationTree.get("parameters/playback").travel("Idle_Right")

func set_health(progress_bar, health, max_health):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]
	pass

func attack():
	if is_alive == true:
		is_attacking = true
		# Trigger attack animation
		$AnimationTree.get("parameters/playback").travel("Stab_Left")

func finish_attack():
	is_attacking = false

func finish_hurt():
	is_hurting = false

func enemy_attack(value):
	current_health = current_health - value

func enemy():
	pass
 
func _gethurt():
	$AnimationTree.get("parameters/playback").travel("Hurt")
 
func focus():
	_focus.show()
 
func unfocus():
	_focus.hide()
 
func take_damage(value):
	is_hurting = true
	current_health -= value
	if current_health <= 0:
		current_health =0
