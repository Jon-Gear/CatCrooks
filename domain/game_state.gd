class_name GameState
extends RefCounted

var wave_number: int = 0
var points: int = 0
var wave_survived: int = 0
var final_score: int = 0
var alive_brothers: int = 2


func reset_round() -> void:
	wave_number = 0
	points = 0
	wave_survived = 0
	final_score = 0
	alive_brothers = 2
