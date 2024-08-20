extends CharacterBody3D

const zoom_out_params := Vector3(5.0, 1.0, 0.5)
const zoom_in_params := Vector3(2.0, 1.3, 0.5)
const bullet_scene = preload("res://addons/depth_buffer/example/bullet.tscn")

@onready var camera_pivot := get_node("%CameraPivot") as Node3D
@onready var spring_arm := get_node("%SpringArm3D") as SpringArm3D
@onready var cam := get_node("%Camera3D") as Camera3D
@onready var crosshair := get_node("%Crosshair") as Control

@export var jump_height := 2.3
@export var jump_apex_time := 0.35
@export var move_speed := 7.0
@export var look_sensitivity := 0.01

var _jump_velocity := 1.0
var _jump_gravity := 1.0

func _ready() -> void:
	Input.warp_mouse(DisplayServer.window_get_size()/2)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	calc_physics()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += Vector3.DOWN * _jump_gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = _jump_velocity
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_input_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			crosshair.visible = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			crosshair.visible = true
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
	
		if event is InputEventMouseMotion:
			camera_pivot.rotation.y = wrapf(camera_pivot.rotation.y - event.relative.x*look_sensitivity, 0.0, 2.0*PI)
			camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y*look_sensitivity, -PI/3.0, PI/4.0)
		
		if event.is_action_pressed("aim"):
			spring_arm.spring_length = zoom_in_params.x
			cam.h_offset = zoom_in_params.y
			cam.v_offset = zoom_in_params.z
		if event.is_action_released("aim"):
			spring_arm.spring_length = zoom_out_params.x
			cam.h_offset = zoom_out_params.y
			cam.v_offset = zoom_out_params.z
		
		if event.is_action_pressed("shoot"):
			shoot_bullet()

func shoot_bullet() -> void:
	var ray_length = 1000.0
	var space_state = get_world_3d().direct_space_state
	var mousepos = DisplayServer.window_get_size()/2

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(origin, end, 0x1)

	var result = space_state.intersect_ray(query)
	var target_pos = cam.global_position + \
					 cam.global_transform.basis*Vector3(cam.h_offset, cam.v_offset, 0.0) + \
					 cam.global_transform.basis*Vector3.FORWARD*ray_length
	if not result.is_empty():
		target_pos = result['position']
	
	var bullet = bullet_scene.instantiate()
	bullet.global_transform = global_transform
	bullet.look_at_from_position(global_position, target_pos)
	get_parent().add_child(bullet)
	
func calc_physics() -> void:
	_jump_velocity = 2.0 * jump_height / jump_apex_time
	_jump_gravity = 2.0 * jump_height / jump_apex_time**2.0
