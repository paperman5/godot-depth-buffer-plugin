extends Node
## An autoload for creating and keeping track of the [DepthBufferViewport]s 
## used to encode depth buffers.

const _viewport_scene = preload("res://addons/depth_buffer/depth_buffer_viewport.tscn")

var _viewports : Array[DepthBufferViewport] = []

## Creates a [DepthBufferViewport].[br]
## [param cull_mask] indicates the cull mask the camera of the new viewport will have, and
## [param viewport_target] indicates the viewport that it will track (size & camera position).[br][br]
## NOTE: If a [DepthBufferViewport] with this [param cull_mask] already exists, it will return that [DepthBufferViewport].[br][br]
## TIP: To set the cull mask, use bitwise operations. For example, a mask with layers 2 & 3 set would be 
## [code](1 << 1) | (1 << 2)[/code].
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
	
	vp = _viewport_scene.instantiate() as DepthBufferViewport
	vp.name += str(cull_mask)
	add_child(vp)
	
	vp.target_viewport = vp_target
	vp.cull_mask = cull_mask
	_viewports.append(vp)
	
	return vp

## Returns a currently active [DepthBufferViewport] with the specified [param cull_mask],
## if one exists. If a [DepthBufferViewport] with the specified mask does not exist,
## it will return [code]null[/code].
func get_viewport_of_cull_mask(cull_mask : int) -> DepthBufferViewport:
	var viewport : DepthBufferViewport = null
	for vp : DepthBufferViewport in _viewports:
		if vp.cull_mask == cull_mask:
			viewport = vp
			break
	return viewport

## Calls [code]queue_free[/code] on the [DepthBufferViewport] with the specified
## [param cull_mask], if it exists.[br][br]
## NOTE: If the [DepthBufferViewport] is currently being used in an effect,
## removing it may cause errors.
func remove_viewport_of_cull_mask(cull_mask : int) -> void:
	var viewport = get_viewport_of_cull_mask(cull_mask)
	if is_instance_valid(viewport):
		viewport.queue_free()
