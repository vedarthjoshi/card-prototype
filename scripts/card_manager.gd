class_name CardManager
extends Node2D

const COLLSION_MASK_CARD = 1
const COLLSION_MASK_CARD_SLOT = 2
const DEFUALT_CARD_SPEED = 0.5

var card_being_dragged : Node2D
var screen_size
var is_hovering_over_card

@export var player_hand : PlayerHand
@export var input_manager : InputManager

func _ready() -> void:
	screen_size = get_viewport_rect().size
	input_manager.left_mouse_button_released.connect(on_left_click_released)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
		

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.is_pressed():
			#var card = raycast_check_for_card()
			#if card:
				#start_drag(card)
		#else :
			#if card_being_dragged:
				#finish_drag()

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLSION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size()>0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLSION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size()>0:
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	#Assumeed that first card in the array of cards variable is the top most and has highest z index
	var highest_z_card : Card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Looping through the rest of the cards? checking for a higher z index
	for i in range(1, cards.size()):
		var current_card :Card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
		

func connect_card_signals(card : Card):
	print(card)
	card.connect("hovered", on_hover_over_card)
	card.connect("hovered_off", on_hover_off_card)

func heighlight_card(card: Card, hovered: bool):
	if hovered:
		card.scale *= 1.05
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1

func on_hover_over_card(card):
	if !is_hovering_over_card:
		is_hovering_over_card = true
		heighlight_card(card, true)

func on_hover_off_card(card):
	if !card_being_dragged:
		heighlight_card(card, false)   
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			heighlight_card(new_card_hovered, true)
		else:
			is_hovering_over_card = false

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1,1)

func finish_drag():
	card_being_dragged.scale *= 1.05
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		player_hand.remove_card_from_hand(card_being_dragged)
		# Card Dropped in Empty Card Slot
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
	else:
		player_hand.add_card_to_hand(card_being_dragged, DEFUALT_CARD_SPEED)
	card_being_dragged = null
