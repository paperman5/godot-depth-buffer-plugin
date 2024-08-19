extends Node

const viewport_scene = preload("res://addons/depth_buffer/depth_render_viewport.tscn")

func add_depth_buffer_viewport(render_layer : int, viewport_target : NodePath = NodePath("/root")) -> DepthBufferViewport:
	var vpt = get_node_or_null(viewport_target)
	if not is_instance_valid(vpt) or vpt is not Viewport:
		push_warning("Invalid path to viewport target, or target is not a viewport")
		return null
	var vp = viewport_scene.instantiate() as DepthBufferViewport
	add_child(vp)
	vp.set_deferred("cull_mask", 1 << clampi(render_layer-1, 0, 19))
	vp.set_deferred("target_viewport", vpt)
	return vp

func get_viewport_texture() -> ViewportTexture:
	return (get_child(0) as DepthBufferViewport).get_texture()
