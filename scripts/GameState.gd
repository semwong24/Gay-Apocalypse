extends Node

var comic_playing = false
var ui_open = false
var reset_player_rotation: bool = false
var is_new_game: bool = false

func reset():
	comic_playing = false
	ui_open = false
	is_new_game = false
