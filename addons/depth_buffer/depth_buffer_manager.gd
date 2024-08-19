extends Node

const viewport_scene = preload("res://addons/depth_buffer/depth_render_viewport.tscn")

func create_depth_buffer_viewport(render_layer : int, viewport_target : NodePath = NodePath("/root")) -> DepthBufferViewport:
	var vp_target = get_node_or_null(viewport_target)
	
	if not is_instance_valid(vp_target) or vp_target is not Viewport:
		push_warning("Invalid path to viewport target, or target is not a viewport")
		return null
	
	var vp = viewport_scene.instantiate() as DepthBufferViewport
	add_child(vp)
	
	# Wait until ready so onready variables are valid
	if not vp.is_node_ready():
		await vp.ready
	
	vp.target_viewport = vp_target
	if not vp.is_viewport_ready():
		await vp.viewport_ready
	
	# Set cull mask after target viewport so target cam gets cull mask set too
	vp.cull_mask = 1 << clampi(render_layer-1, 0, 19)
	return vp

func add_shader_mesh_to_camera(cam : Camera3D, render_layer : int = 1) -> FullscreenShaderMesh:
	# Adds a fullscreen shader mesh to a specific camera, which will be toggled
	# on or off depending on the camera's active state.
	var fsm = FullscreenShaderMesh.new()
	fsm.target_camera = cam
	fsm.reparent_to_active_cam = false
	fsm.layers = 1 << clampi(render_layer-1, 0, 19)
	cam.add_child(fsm)
	fsm.transform = Transform3D.IDENTITY
	return fsm

func add_shader_mesh_to_viewport(viewport_path : NodePath = NodePath("/root"), render_layer : int = 1) -> FullscreenShaderMesh:
	# Adds a fullscreen shader mesh to a viewport's camera, which will reparent itself
	# to the new camera when the active camera is changed in a viewport.
	var vp = get_node_or_null(viewport_path) as Viewport
	if not is_instance_valid(vp): return null
	var cam = vp.get_camera_3d()
	if not is_instance_valid(cam): return null
	var fsm = FullscreenShaderMesh.new()
	fsm.target_camera = cam
	fsm.reparent_to_active_cam = true
	fsm.layers = 1 << clampi(render_layer-1, 0, 19)
	cam.add_child(fsm)
	fsm.transform = Transform3D.IDENTITY
	return fsm
