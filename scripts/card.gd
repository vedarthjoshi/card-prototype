class_name Card
extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal hovered
signal hovered_off

var hand_position

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	hovered.emit(self)

func _on_area_2d_mouse_exited() -> void:
	hovered_off.emit(self)

func diss():
	animation_player.play("diss")
