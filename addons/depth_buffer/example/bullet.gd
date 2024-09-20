extends CharacterBody3D


const SPEED = 20.0


func _ready() -> void:
	velocity = -transform.basis.z * SPEED


func _physics_process(delta: float) -> void:
	move_and_slide()
	var coll = get_last_slide_collision()
	if coll != null:
		var body = coll.get_collider()
		if body.has_method("on_bullet_hit"):
			body.on_bullet_hit()
	if coll != null or abs(global_position.x) > 1000 or abs(global_position.y) > 1000 or abs(global_position.z) > 1000:
		queue_free()
