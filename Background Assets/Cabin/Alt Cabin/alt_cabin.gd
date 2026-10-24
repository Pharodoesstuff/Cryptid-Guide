extends Level

const DEATH_SCENE = preload("res://Characters/Main Character/player_death(s).tscn") # Adjust path to where player_death(s).tscn is saved
@export var furniture_dialogue_phase_1: DialogueArea2d
@export var furniture_dialogue_phase_2: DialogueArea2d


func trigger_player_death() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Spawn the death scene at the player's current position
		var death_instance = DEATH_SCENE.instantiate()
		death_instance.global_position = player.global_position
		add_child(death_instance)
		
		# Play the death animation on the newly spawned node
		var anim_player: AnimationPlayer = death_instance.get_node("AnimationPlayer")
		if anim_player:
			anim_player.play("alt_death_down") # Or "alt_death_down", "death_side", etc.
		
		# Remove/hide the original player
		player.queue_free()

func _ready() -> void:
	super._ready()



	# 3. Connect dialogue finished signal
	# (Assuming your dialogue Area2D emits a signal like 'dialogue_finished' or 'interaction_ended')

func _on_furniture_dialogue_finished() -> void:
	pass
