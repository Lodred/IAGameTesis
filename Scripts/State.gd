extends Node

var player_position = Vector2(136, -314)
var enemy_to_remove_id = []

var Player_alive = true
var Player_max_health = 80
var Player_current_health = 80
var Player_speed = 10
var Player_max_damage = 6
var Player_min_damage = 3

var Ally_alive = true
var Ally_max_health = 60
var Ally_current_health = 60
var Ally_speed = 9
var Ally_max_damage = 6
var Ally_min_damage = 3

var Enemies: Array[Resource] = []

func save_player_position(position):
	player_position = position

func load_player_position():
	return player_position
