extends Node
class_name BookPuzzleManager

@export var closet_node: Node2D # Drag your closet node here in the inspector

var correct_answers: int = 0
var required_correct: int = 3
var puzzle_passed: bool = false

const TOTAL_QUESTIONS: int = 3

func reset_quiz() -> void:
	correct_answers = 0

func answer_correct() -> void:
	correct_answers += 1

func answer_wrong() -> void:
	# Keep going, but score won't increase
	pass

func check_quiz_results() -> void:
	if correct_answers >= TOTAL_QUESTIONS:
		SaveManager.set_persistence("book_quiz_passed")
		print("Quiz passed! Closet interaction unlocked.")
	else:
		print("Quiz failed.")
	
	correct_answers = 0 # Reset counter for subsequent attempts

func cancel_book_dialogue() -> void:
	var canvas_layer = get_tree().root.find_child("DialogueCanvasLayer", true, false)
	if canvas_layer and canvas_layer.has_method("stop_dialogue"):
		canvas_layer.stop_dialogue()
