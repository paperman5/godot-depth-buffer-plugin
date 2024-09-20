extends CompositorEffect
class_name PostProcessSilhouette


@export_flags_3d_render var silhouette_mask := 1<<1
@export_flags_3d_render var obstruction_mask := 1<<2
@export var silhouette_color := Color(0.3, 0.3, 0.3, 0.9)

var silhouette_viewport : DepthBufferViewport
var obstruction_viewport : DepthBufferViewport
var rd : RenderingDevice
var shader : RID
var pipeline : RID


func _init(silhouette_mask_ := 1<<1, obstruction_mask_ := 1<<2, callback_type := EffectCallbackType.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT) -> void:
	rd = RenderingServer.get_rendering_device()
	RenderingServer.call_on_render_thread(_initialize_compute)
	silhouette_mask = silhouette_mask_
	obstruction_mask = obstruction_mask_
	effect_callback_type = callback_type
	if DepthBufferManager.is_node_ready():
		_init_viewports()
	else:
		_init_viewports.call_deferred()


func _init_viewports() -> void:
	silhouette_viewport = DepthBufferManager.create_depth_buffer_viewport(silhouette_mask)
	obstruction_viewport = DepthBufferManager.create_depth_buffer_viewport(obstruction_mask)
	DepthBufferManager.get_tree().process_frame.connect(_update_viewport_update_mode)


func _update_viewport_update_mode() -> void:
	if enabled:
		silhouette_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		obstruction_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		silhouette_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		obstruction_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			# Freeing our shader will also free any dependents such as the pipeline!
			RenderingServer.free_rid(shader)


#region Code in this region runs on the rendering thread.
# Compile our shader at initialization.
func _initialize_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return
	
	# Compile our shader.
	var shader_file := load("res://addons/depth_buffer/post_process_silhouette.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	shader = rd.shader_create_from_spirv(shader_spirv)
	if shader.is_valid():
		pipeline = rd.compute_pipeline_create(shader)


# Called by the rendering thread every frame.
func _render_callback(p_effect_callback_type: EffectCallbackType, p_render_data: RenderData) -> void:
	if rd and pipeline.is_valid():
		if not is_instance_valid(silhouette_viewport) or not is_instance_valid(obstruction_viewport) \
				or not silhouette_viewport.is_viewport_ready() or not obstruction_viewport.is_viewport_ready():
			return
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers := p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size: Vector2i = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return
			
			# We can use a compute shader here.
			@warning_ignore("integer_division")
			var x_groups := (size.x - 1) / 8 + 1
			@warning_ignore("integer_division")
			var y_groups := (size.y - 1) / 8 + 1
			var z_groups := 1
			
			# Create push constant.
			# Must be aligned to 16 bytes and be in the same order as defined in the shader.
			var push_constant := PackedFloat32Array([
				size.x,
				size.y,
				0.0,
				0.0,
				silhouette_color.r,
				silhouette_color.g,
				silhouette_color.b,
				silhouette_color.a,
			])
			
			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
			var view_count: int = render_scene_buffers.get_view_count()
			for view in view_count:
				# Get the RID for the depth & color images for the compute shader
				var color_image: RID = render_scene_buffers.get_color_layer(view)
				var depth_image: RID = render_scene_buffers.get_depth_layer(view)
				
				# COLOR BUFFER
				var uniform := RDUniform.new()
				uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				uniform.binding = 0
				uniform.add_id(color_image)
				
				# DEPTH BUFFER
				var sampler_state := RDSamplerState.new()
				var sampler := rd.sampler_create(sampler_state)
				var uniform2 := RDUniform.new()
				uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform2.binding = 1
				uniform2.add_id(sampler)
				uniform2.add_id(depth_image)
				
				# SILHOUETTE ENCODED DEPTH BUFFER
				sampler_state = RDSamplerState.new()
				sampler = rd.sampler_create(sampler_state)
				var uniform3 := RDUniform.new()
				var vpt_rid := RenderingServer.texture_get_rd_texture(silhouette_viewport.get_texture().get_rid())
				uniform3.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform3.binding = 2
				uniform3.add_id(sampler)
				uniform3.add_id(vpt_rid)
				
				# OBSTRUCTION ENCODED DEPTH BUFFER
				sampler_state = RDSamplerState.new()
				sampler = rd.sampler_create(sampler_state)
				var uniform4 := RDUniform.new()
				vpt_rid = RenderingServer.texture_get_rd_texture(obstruction_viewport.get_texture().get_rid())
				uniform4.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform4.binding = 3
				uniform4.add_id(sampler)
				uniform4.add_id(vpt_rid)
				
				var uniform_set := UniformSetCacheRD.get_cache(shader, 0, [uniform, uniform2, uniform3, uniform4])
				
				# Run our compute shader.
				var compute_list := rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
#endregion
