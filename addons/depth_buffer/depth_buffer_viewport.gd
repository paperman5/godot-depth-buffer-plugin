@icon("res://addons/depth_buffer/DepthBufferViewport.svg")
class_name DepthBufferViewport
extends SubViewport
## A viewport which displays the depth buffer of a specific render layer(s)/cull mask.
## The [ViewportTexture] is encoded from a 32bit float depth texture as 4 8bit colors
## by directly copying the floating point bits into the color/alpha bits using a [CompositorEffect].
## This [ViewportTexture] can then be used in another shader or [CompositorEffect].

@onready var _cam := get_node("%Camera3D") as Camera3D

## The rendering layers/cull mask to render with this viewport.
@export_flags_3d_render var cull_mask : int:
	get:
		return _cam.cull_mask
	set(value):
		cull_mask = value
		_cam.cull_mask = value

var _viewport_ready := false
## The viewport to mirror with this viewport. The camera for this [DepthBufferViewport]
## will be synchronized with the target viewport's camera every frame.
var target_viewport : Viewport:
	set(value):
		_set_viewport_ready(false)
		target_viewport = value
		world_3d = target_viewport.world_3d if is_instance_valid(target_viewport) else null
		_update()
		await RenderingServer.frame_post_draw
		viewport_ready.emit()

## Emitted with the viewport texture is ready to be used. 
signal viewport_ready


func _ready() -> void:
	# Process after everything else so the camera gets synced correctly
	process_priority = 500
	_cam.process_priority = 500
	
	viewport_ready.connect(_set_viewport_ready.bind(true))
	
	# The compute shaders for the effects use this ViewportTexture, but they
	# don't notify this node that it's being used, so we need to always update
	render_target_update_mode = UPDATE_ALWAYS
	# Needs to be bilinear no matter the project setting
	scaling_3d_mode = SCALING_3D_MODE_BILINEAR
	
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


## Synchronizes the camera to the target camera. This is automatically
## called every frame with the target viewport's camera.
func sync_camera(sync_to : Camera3D) -> void:
	_cam.keep_aspect 	= sync_to.keep_aspect
	_cam.projection 	= sync_to.projection
	_cam.fov 			= sync_to.fov
	_cam.near 			= sync_to.near
	_cam.far 			= sync_to.far
	_cam.global_transform = sync_to.get_camera_transform()


func _set_viewport_ready(value : bool):
	_viewport_ready = value


## Returns whether the viewport texture is ready to be used.
func is_viewport_ready() -> bool:
	return _viewport_ready
