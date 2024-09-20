extends CharacterBody3D


@onready var orig_pos = global_position
var t := randf_range(0.0, 2.0*PI)


func _physics_process(delta: float) -> void:
	t = wrapf(t + delta, 0.0, 2.0*PI)
	global_position = orig_pos + Vector3(sin(t), 0.0, cos(t))


func _on_respawn_timer_timeout():
	process_mode = PROCESS_MODE_PAUSABLE
	visible = true


func on_bullet_hit():
	process_mode = PROCESS_MODE_DISABLED
	visible = false
	$RespawnTimer.start(5.0)
