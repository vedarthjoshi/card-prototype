class_name Deck
extends Node2D

@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var rich_text_label: RichTextLabel = $RichTextLabel

const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_DRAW_SPEED = 0.2

var card_database_refrence = preload("res://scripts/CardDatabase.gd")

@export_category("Prerequisites")
@export var CardManagerNode : CardManager
@export var PlayerHandNode : PlayerHand

var player_deck = ["Knight", "Archer", "Demon", "Knight"]

func _ready() -> void:
	rich_text_label.text = "[center]"+str(player_deck.size())+"[/center]"

func draw_card():
	player_deck.shuffle()
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	if player_deck.size() == 0:
		collision_shape_2d.disabled = true
		sprite_2d.hide()
		rich_text_label.hide()
	
	rich_text_label.text = "[center]"+str(player_deck.size())+"[/center]"
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card: Card = card_scene.instantiate()
	new_card.position = position
	new_card.z_index = 3
	new_card.get_node("Attack").text = str(card_database_refrence.CARDS[card_drawn_name][0])
	new_card.get_node("Health").text = str(card_database_refrence.CARDS[card_drawn_name][1])
	var card_image_path = "res://assets/" + card_drawn_name + "_card.png"
	new_card.get_node("CardImg/CardImage").texture = load(card_image_path)
	CardManagerNode.add_child(new_card)
	new_card.name = "Card"
	PlayerHandNode.add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
