class_name FullscreenShaderMesh
extends MeshInstance3D

var target_camera : Camera3D
var reparent_to_active_cam := false
var _cam_active_prev := true

signal camera_active_changed(active : bool)

func _ready() -> void:
	process_priority = 500
	extra_cull_margin = 16384
	camera_active_changed.connect(_on_camera_active_changed)
	_create_shader_mesh()
	
	if is_instance_valid(target_camera):
		_cam_active_prev = target_camera.current

func set_shader(shader : Shader) -> void:
	material_override = ShaderMaterial.new()
	material_override.shader = shader

func set_shader_parameter(param: StringName, value: Variant) -> void:
	if material_override is not ShaderMaterial: return
	material_override.set_shader_parameter(param, value)

func _process(_delta: float) -> void:
	if is_instance_valid(target_camera):
		# Track the 'current' property of the target cam and emit signals
		if _cam_active_prev != target_camera.current:
			_cam_active_prev = target_camera.current
			camera_active_changed.emit(target_camera.current)

func _create_shader_mesh() -> void:
	# Creates a single triangle for a shader to be applied to.
	# See https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html#an-optimization
	
	# Triangle data
	var verts = PackedVector3Array()
	verts.append(Vector3(-1.0, -1.0, 0.0))
	verts.append(Vector3(-1.0, 3.0, 0.0))
	verts.append(Vector3(3.0, -1.0, 0.0))
	
	# Create the mesh array from the triangle
	var mesh_array = []
	mesh_array.resize(Mesh.ARRAY_MAX) #required size for ArrayMesh Array
	mesh_array[Mesh.ARRAY_VERTEX] = verts #position of vertex array in ArrayMesh Array
	
	# Create mesh from mesh_array:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	mesh = am

func _on_camera_active_changed(active : bool) -> void:
	if not active and reparent_to_active_cam:
		# Target camera has become inactive and we should reparent to the active camera
		var vp = get_viewport()
		if not is_instance_valid(vp): return
		target_camera = vp.get_camera_3d()
		if not is_instance_valid(target_camera): return
		get_parent().remove_child(self)
		target_camera.add_child(self)
		transform = Transform3D.IDENTITY
		visible = true
		_cam_active_prev = target_camera.current
	else:
		visible = active
