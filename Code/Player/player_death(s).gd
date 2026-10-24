# res://Code/Player/player_death(s).gd
extends CharacterBody2D

@export var menu_options_scene: PackedScene

@onready var sprite: Sprite2D = $DEATH 
@onready var animation_player: AnimationPlayer = $AnimationPlayer 
@onready var camera_2d: Camera2D = $Camera2D # Make sure node name matches your scene[cite: 6, 7]

func _ready() -> void:
	if camera_2d:
		camera_2d.make_current() # Immediately grabs viewport focus before Player is freed
	animation_player.animation_finished.connect(_on_animation_finished) 

func setup(facing_scale_x: float, anim_dir: String, death_type: String = "default") -> void:
	# Fix 1: Match left/right facing flip
	sprite.scale.x = facing_scale_x
	
	# Fix 3: Construct exact animation name ("death_down", "death_side", "death_up" or "alt_death_...")
	var prefix = "alt_death_" if death_type == "alt" else "death_"
	var anim_name = prefix + anim_dir
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		animation_player.play("death_down")

func _on_animation_finished(_anim_name: String) -> void:
	transition_to_menu()

func transition_to_menu() -> void:
	if not menu_options_scene:
		push_error("menu_options_scene is not assigned on Player Death!")
		return

	# 1. Create a full-screen black canvas overlay
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	get_tree().root.add_child(canvas)
	
	# 2. Fade to black over 0.8 seconds
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.8)
	await tween.finished
	
	# 3. Fix 4: Fully unload the level and change scene to Menu Options
	get_tree().change_scene_to_packed(menu_options_scene)
	
	# Cleanup overlay
	canvas.queue_free()
