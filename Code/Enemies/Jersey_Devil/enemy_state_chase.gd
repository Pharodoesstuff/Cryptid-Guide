class_name EnemyStateChase extends EnemyState

@export var anim_name : String = "Devil"
@export var turn_rate : float = 15.0
@export var attack_area : HurtBox
@export var chase_speed : float = 322.0
@export var state_aggro_duration : float = 0.5
@export var next_state : EnemyState

var _timer : float = 0.0
var _direction : Vector2

func enter() -> void:
	_timer = state_aggro_duration
	if PlayerManager.player:
		_direction = enemy.global_position.direction_to(PlayerManager.player.global_position)
		enemy.SetDirection(_direction)
	enemy.UpdateAnimation(anim_name)
	if attack_area:
		attack_area.monitoring = true

func exit() -> void:
	if attack_area:
		attack_area.monitoring = false

func physics(_delta: float) -> EnemyState:
	if PlayerManager.player:
		var target_dir: Vector2 = enemy.global_position.direction_to(PlayerManager.player.global_position)
		_direction = _direction.lerp(target_dir, turn_rate * _delta)
		enemy.velocity = _direction * chase_speed
		if enemy.SetDirection(_direction):
			enemy.UpdateAnimation(anim_name)
	return null
