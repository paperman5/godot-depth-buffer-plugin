class_name DepthBufferViewport
extends SubViewport

@onready var cam := get_node("%Camera3D") as Camera3D

@export_flags_3d_render var cull_mask : int:
	get:
		return cam.cull_mask
	set(value):
		cull_mask = value
		cam.cull_mask = value
		if is_instance_valid(target_viewport) and is_instance_valid(target_viewport.get_camera_3d()):
			target_viewport.get_camera_3d().cull_mask &= ~cull_mask

var _viewport_ready := false
var target_viewport : Viewport:
	set(value):
		_set_viewport_ready(false)
		target_viewport = value
		world_3d = target_viewport.world_3d if is_instance_valid(target_viewport) else null
		_update()
		await RenderingServer.frame_post_draw
		viewport_ready.emit()

signal viewport_ready

func _ready() -> void:
	viewport_ready.connect(_set_viewport_ready.bind(true))
	
	_update()

func _process(_delta: float) -> void:
	_update()

func _update() -> void:
	if not is_instance_valid(target_viewport):
		return
	var target_cam = target_viewport.get_camera_3d()
	if not is_instance_valid(target_cam):
		return
	size = target_viewport.size * target_viewport.scaling_3d_scale
	sync_camera(target_cam)

func sync_camera(sync_to : Camera3D) -> void:
	cam.keep_aspect 	= sync_to.keep_aspect
	#cam.h_offset 		= sync_to.h_offset
	#cam.v_offset 		= sync_to.v_offset
	cam.projection 		= sync_to.projection
	cam.fov 			= sync_to.fov
	cam.near 			= sync_to.near
	cam.far 			= sync_to.far
	cam.global_transform = sync_to.get_camera_transform()

func _set_viewport_ready(value : bool):
	_viewport_ready = value

func is_viewport_ready() -> bool:
	return _viewport_ready
