class_name InputManager
extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

@export var card_manager_refrence : CardManager
@export var deck_refrence : Deck
const COLLSION_MASK_CARD = 1
const COLLSION_MASK_DECK = 4

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			left_mouse_button_clicked.emit()
			raycast_at_cursor()
		else :
			left_mouse_button_released.emit()


func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size()>0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLSION_MASK_CARD:
			# Card Clicked
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_refrence.start_drag(card_found)
		elif result_collision_mask == COLLSION_MASK_DECK:
#			 Deck clicked 
			deck_refrence.draw_card()
