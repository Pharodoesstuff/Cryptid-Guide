extends Area2D

# Speed threshold to allow tiny micro-movements without killing instantly
@export var speed_threshold: float = 2.0

# Choose "default" or "alt" depending on which death animation you want to play
@export var death_type: String = "default" 

func _physics_process(_delta: float) -> void:
	# If the hazard isn't visible/active, do nothing
	if not visible:
		return
	
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body is CharacterBody2D:
			# Skip if the player is already dying/dead
			if "is_dead" in body and body.is_dead:
				continue
			
			# Check actual movement velocity
			if body.velocity.length() > speed_threshold:
				# Set flag so it doesn't trigger twice in the same frame
				if "is_dead" in body:
					body.is_dead = true
				
				# Call die with the required string argument ('default' or 'alt')
				body.die.call_deferred(death_type)
