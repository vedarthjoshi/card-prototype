class_name PlayerHand
extends Node2D

#@export var HAND_COUNT = 8
const DEFAULT_CARD_SPEED = 0.5


#const later
@export_group("Screen Variables")
@export var CARD_WIDTH : int = 25
@export var HAND_Y_POSITION : int = 160

var player_hand = []
var center_screen_x

func _ready() -> void:
	center_screen_x = get_viewport_rect().size.x /2


func add_card_to_hand(card: Card, speed: float):
	if card not in player_hand:
		player_hand.insert(0,card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.hand_position, speed)

func update_hand_positions(speed):
	for i in range(player_hand.size()):
		# Get new card position based in index
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card: Card = player_hand[i]
		card.hand_position = new_position
		animate_card_to_position(card, new_position, speed)

func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width/2
	return x_offset

func animate_card_to_position(card, new_position, speed: float):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_SPEED)
