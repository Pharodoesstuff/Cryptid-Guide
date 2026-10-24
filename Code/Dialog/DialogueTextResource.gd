extends DE
class_name DialogueText

@export var speaker_img: Texture
@export var speaker_img_Hframes: int = 1
@export var speaker_img_rest_frame: int = 0

@export_multiline var text: String
@export_range(0.1, 30.0, 0.1 ) var text_speed: float = 30.0

@export var text_sound: AudioStream
@export var text_volume_db: int
@export var text_volume_pitch_min: float = 0.85
@export var text_volume_pitch_max: float = 1.15
@export var reset_camera_to_player: bool = false # Toggle to reset camera back to player mid-dialogue

@export var camera_position: Vector2 = Vector2(999.999, 999.999)
@export_range(0.05, 10.0, 0.05 ) var camera_transition_time: float = 1.0


@export var auto_advance: bool = false
@export_range(0.0, 10.0, 0.1) var auto_advance_delay: float = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
