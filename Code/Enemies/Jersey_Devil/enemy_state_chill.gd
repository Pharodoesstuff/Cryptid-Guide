class_name EnemyStateChill extends EnemyState

@export var anim_name: String = "DDevil"
@export var chase_state: EnemyState

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.UpdateAnimation(anim_name)

func physics(delta: float) -> EnemyState:
	# If the player moves while the enemy is aggressive/hungry, switch to chase
	if enemy.is_hungry and PlayerManager.player:
		if PlayerManager.player.velocity.length() > 0.1:
			EventBus.keepdark.emit()
			return chase_state

	return null
