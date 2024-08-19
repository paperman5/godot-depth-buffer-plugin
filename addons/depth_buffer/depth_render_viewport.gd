class_name DepthBufferViewport
extends SubViewport

const encode_shader := preload("res://addons/depth_buffer/depth_encode.gdshader")

@onready var cam := get_node("%Camera3D") as Camera3D
@onready var shader_mesh := get_node("%ShaderMesh") as MeshInstance3D

@export_flags_3d_render var cull_mask : int:
	get:
		return cam.cull_mask
	set(value):
		cull_mask = value
		cam.cull_mask = value
		shader_mesh.layers = value

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
	
	# Create a single triangle out of vertices:
	var verts = PackedVector3Array()
	verts.append(Vector3(-1.0, -1.0, 0.0))
	verts.append(Vector3(-1.0, 3.0, 0.0))
	verts.append(Vector3(3.0, -1.0, 0.0))
	
	# Create an array of arrays.
	# This could contain normals, colors, UVs, etc.
	var mesh_array = []
	mesh_array.resize(Mesh.ARRAY_MAX) #required size for ArrayMesh Array
	mesh_array[Mesh.ARRAY_VERTEX] = verts #position of vertex array in ArrayMesh Array
	
	# Create mesh from mesh_array:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	shader_mesh.mesh = am
	
	# Create shader material
	shader_mesh.layers = cam.cull_mask
	var mat = ShaderMaterial.new()
	mat.shader = encode_shader
	shader_mesh.material_override = mat
	
	_update()

func _process(_delta: float) -> void:
	_update()

func _update() -> void:
	if not is_instance_valid(target_viewport):
		return
	var target_cam = target_viewport.get_camera_3d()
	if not is_instance_valid(target_cam):
		return
	size = target_viewport.size
	sync_camera(target_cam)

func sync_camera(sync_to : Camera3D) -> void:
	cam.keep_aspect 	= sync_to.keep_aspect
	cam.h_offset 		= sync_to.h_offset
	cam.v_offset 		= sync_to.v_offset
	cam.projection 		= sync_to.projection
	cam.fov 			= sync_to.fov
	cam.near 			= sync_to.near
	cam.far 			= sync_to.far
	cam.global_transform = sync_to.global_transform

func _set_viewport_ready(value : bool):
	_viewport_ready = value

func is_viewport_ready() -> bool:
	return _viewport_ready
