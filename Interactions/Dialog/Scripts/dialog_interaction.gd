@tool

class_name DialogueSystemNode extends CanvasLayer

var is_active: bool = false
var dialogue_queue: Array[String] = []

@onready var dialog_ui: Control = $"Dialog UI"
@onready var rich_text_label: RichTextLabel = $"Dialog UI/PanelContainer/RichTextLabel"
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child(self)
		return
	
	# Start with the dialogue UI hidden
	hide_dialog()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event.is_action_pressed("Accept"):
		advance_dialogue()

func start_dialogue(lines: Array[String], speaker_name: String = "") -> void:
	dialogue_queue = lines.duplicate()
	
	if speaker_name != "":
		name_label.text = speaker_name
		name_label.visible = true
	else:
		name_label.visible = false
		
	show_dialog()
	advance_dialogue()

func advance_dialogue() -> void:
	if dialogue_queue.size() > 0:
		rich_text_label.text = dialogue_queue.pop_front()
	else:
		hide_dialog()

func show_dialog() -> void:
	is_active = true
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func hide_dialog() -> void:
	is_active = false
	dialog_ui.visible = false
	dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
