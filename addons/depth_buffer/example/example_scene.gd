extends Node3D


func _ready() -> void:
	setup_actions()
	spawn_enemies()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		var cam = get_viewport().get_camera_3d()
		var compositor = Compositor.new()
		var effect = PostProcessSilhouette.new()
		compositor.compositor_effects = [effect]
		cam.compositor = compositor


func setup_actions() -> void:
	InputMap.add_action("move_forward")
	InputMap.add_action("move_backward")
	InputMap.add_action("move_left")
	InputMap.add_action("move_right")
	InputMap.add_action("jump")
	InputMap.add_action("aim")
	InputMap.add_action("shoot")
	InputMap.add_action("toggle_input_capture")
	
	var ev = InputEventKey.new()
	ev.keycode = KEY_W
	InputMap.action_add_event("move_forward", ev)
	ev = InputEventKey.new()
	ev.keycode = KEY_S
	InputMap.action_add_event("move_backward", ev)
	ev = InputEventKey.new()
	ev.keycode = KEY_A
	InputMap.action_add_event("move_left", ev)
	ev = InputEventKey.new()
	ev.keycode = KEY_D
	InputMap.action_add_event("move_right", ev)
	ev = InputEventKey.new()
	ev.keycode = KEY_SPACE
	InputMap.action_add_event("jump", ev)
	ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("aim", ev)
	ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shoot", ev)
	ev = InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	InputMap.action_add_event("toggle_input_capture", ev)


func spawn_enemies() -> void:
	var enemy = load("res://addons/depth_buffer/example/enemy.tscn")
	for c : Node3D in $EnemySpawns.get_children():
		var e = enemy.instantiate()
		e.global_transform = c.global_transform
		add_child(e)
