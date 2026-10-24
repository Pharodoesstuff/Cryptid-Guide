class_name HurtBox extends Area2D

@export var damage : int = 1
@export var death_type : String = "default" # e.g. "devil", "fire", "spikes"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect( AreaEntered )
	pass # Replace with function body.



func AreaEntered( a : Area2D ) -> void: 
	if a is HitBox:
		a.take_damage( self )
	pass
