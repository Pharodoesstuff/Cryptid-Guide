# res://Code/Level Code/cabin_level.gd
extends "res://Code/Level Code/level.gd" # or 'extends Level' if level.gd uses class_name Level

@onready var hidden_entrance: TileMapLayer = $"cabin Design/Hidden Entrance"
@onready var entrance_block: CollisionShape2D = $"Wall Borders/Entrance Block"
@onready var book_dialogue_node: Area2D = $"Dialogue/Book"
@onready var closet: Area2D = $"Interactions/Closet"
@onready var free_cryptid: TileMapLayer = $"cabin Design/Furniture 2/Free Cryptid"
@onready var freed_souls: DialogueArea2d = $"Freed Souls"
@onready var dialogue: BookPuzzleManager = $Dialogue
@onready var book: DialogueArea2d = $Book
@onready var door: TileMapLayer = $"cabin Design/Door"
@onready var last_woof: Area2D = $"Last Woof"
@onready var booky: DialogueArea2d = $Dialogue/Book
@onready var freebear: Sprite2D = $Freebear



@export var cleared_book_dialogue: Resource


func _ready() -> void:
	super._ready() # Runs the parent level.gd ready function first
	if LevelManager.has_signal("level_loaded"):
		await LevelManager.level_loaded
	
	# Reset player movement state upon returning to the Cabin
	EventBus.player_freeze_requested.emit(false)
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.can_move = true
		
	# --- PERMANENT VOID LOCKOUT ---
	if SaveManager.has_persistence("void_cutscene_completed"):
		var void_trans = get_node_or_null("Transitions/Void")
		if is_instance_valid(void_trans):
			void_trans.queue_free()
	
	# Reset player movement state upon returning to the Cabin
	EventBus.player_freeze_requested.emit(false)
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.can_move = true
		
	if SaveManager.has_persistence("attic_power_on"):
		freed_souls.monitorable = true
		freed_souls.monitoring = true
		
		book.monitorable = true
		book.monitoring = true
		
		freebear.visible = true
		freebear.visible = true
		
		last_woof.monitorable = true
		last_woof.monitoring = true
		
		
		free_cryptid.visible = true
		
		_released_cryptids()
		
	else:
		freed_souls.monitorable = false	
		freed_souls.monitoring = false
		
		book.monitorable = false
		book.monitoring = false
		
		free_cryptid.visible = false
		
		last_woof.monitorable = false
		last_woof.monitoring = false
		
		freebear.visible = false
		freebear.visible = false
# Export dialogue resources so you can assign new post-cleared text in the Inspector
	if closet:
		closet.ambush_completed.connect(_on_ambush_completed)

	if SaveManager.has_persistence("closet_ambush_cleared"):
		apply_cleared_state()
	
	EventBus.attic_event_completed.connect(_released_cryptids)
		
	
	
func _on_ambush_completed() -> void:
	apply_cleared_state()

func apply_cleared_state() -> void:
	# 1. Reveal Hidden Entrance
	if hidden_entrance:
		hidden_entrance.visible = true
		booky.queue_free()
		
	# 2. Disable physics collision for Entrance Block
	if entrance_block:
		entrance_block.set_deferred("disabled", true)
		
	# 3. Swap Book dialogue to the new text resources
	if book_dialogue_node and cleared_book_dialogue:
		book_dialogue_node.dialogue = cleared_book_dialogue

func _released_cryptids() -> void:
	remove_child(dialogue)
	freed_souls.monitoring = true
	freed_souls.monitorable = true
	pass

func _open_door()-> void:
	door.queue_free()
	pass
