extends Node


const viewport_scene = preload("res://addons/depth_buffer/depth_buffer_viewport.tscn")

var _viewports : Array[DepthBufferViewport] = []


func create_depth_buffer_viewport(cull_mask : int, viewport_target : NodePath = NodePath("/root")) -> DepthBufferViewport:
	
	var vp_target = get_node_or_null(viewport_target)
	if not is_instance_valid(vp_target) or vp_target is not Viewport:
		push_warning("Invalid path to viewport target, or target is not a viewport")
		return null
	
	var vp = get_viewport_of_cull_mask(cull_mask)
	if is_instance_valid(vp):
		if vp.target_viewport != vp_target:
			vp.target_viewport = vp_target
		return vp
	
	vp = viewport_scene.instantiate() as DepthBufferViewport
	vp.name += str(cull_mask)
	add_child(vp)
	
	vp.target_viewport = vp_target
	vp.cull_mask = cull_mask
	_viewports.append(vp)
	
	return vp


func get_viewport_of_cull_mask(cull_mask : int) -> DepthBufferViewport:
	var viewport : DepthBufferViewport = null
	for vp : DepthBufferViewport in _viewports:
		if vp.cull_mask == cull_mask:
			viewport = vp
			break
	return viewport


func remove_viewport_of_cull_mask(cull_mask : int) -> void:
	var viewport = get_viewport_of_cull_mask(cull_mask)
	if is_instance_valid(viewport):
		viewport.queue_free()
