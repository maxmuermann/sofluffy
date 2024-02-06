extends Node

@export var target: MeshInstance3D
@export var surface_index: int = 0
@export var cam: Camera3D
@export var viewport: SubViewport

var mesh: ArrayMesh
var meshDataTool: MeshDataTool = MeshDataTool.new()

var done = false

func _process(_delta):
	if done:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mousepos = get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mousepos)
		var direction = cam.project_ray_normal(mousepos)

		print(origin)
		print(direction)

		var uv = uv_for_closest_intersection(origin, direction)

		if(uv != null):
			# move brush sprite to uv
			viewport.move_brush(uv)
			
		# done = true



func _ready() -> void:
	mesh = target.mesh
	meshDataTool.create_from_surface(mesh, surface_index)

func uv_for_closest_intersection(origin: Vector3, direction: Vector3) -> Variant:
	var results: Array = ray_intersects_faces(origin, direction)

	if results.size() == 0:
		return null
	
	var res: Array = results[0]
	# var verts = mesh.get_faces()

	# var vid0: int = res[0] * 3
	# var vid1: int = res[0] * 3 + 1
	# var vid2: int = res[0] * 3 + 2

	# var v0 = target.to_global(verts[vid0])
	# var v1 = target.to_global(verts[vid1])
	# var v2 = target.to_global(verts[vid2])

	meshDataTool.get_face_vertex(res[0], 0)
	var vid0: int = meshDataTool.get_face_vertex(res[0], 0)
	var vid1: int = meshDataTool.get_face_vertex(res[0], 1)
	var vid2: int = meshDataTool.get_face_vertex(res[0], 2)

	var v0 = target.to_global(meshDataTool.get_vertex(vid0))
	var v1 = target.to_global(meshDataTool.get_vertex(vid1))
	var v2 = target.to_global(meshDataTool.get_vertex(vid2))


	print(vid0, ", ", vid1, ", ", vid2)
	print(v0, ", ", v1, ", ", v2)

	var weights: Vector3 = Geometry3D.get_triangle_barycentric_coords(res[1], v0, v1, v2)

	var uv0: Vector2 = meshDataTool.get_vertex_uv(vid0)
	var uv1: Vector2 = meshDataTool.get_vertex_uv(vid1)
	var uv2: Vector2 = meshDataTool.get_vertex_uv(vid2)

	print("uvs: ", uv0, uv1, uv2)
	print("weights: ", weights)

	var uv: Vector2 = uv0 * weights.x + uv1 * weights.y + uv2 * weights.z

	# print("uv: ", uv)

	return uv
	

func ray_intersects_faces(origin: Vector3, direction: Vector3) -> Array:
	var vertices: PackedVector3Array = mesh.get_faces()	
	
	var results: Array = []
	
	var closest_dist: float = 1000000.0 # this is yucky, but Godot has no MAX_FLOAT constant, apparently
	var closest_face: int = -1
	var closest_intersection: Vector3 = Vector3.ZERO


	var i: int = 0
	while i < vertices.size():
		var face_index: int = i / 3
		var a: Vector3 = target.to_global(vertices[i])
		var b: Vector3 = target.to_global(vertices[i + 1])
		var c: Vector3 = target.to_global(vertices[i + 2])

		# print("verts: ", a, b, c)

		var intersects_triangle = Geometry3D.ray_intersects_triangle(origin, direction, a, b, c)

		# TODO: should really collect all intersections here and sort by distance.
		if intersects_triangle != null:
			# print("hit at: ", intersects_triangle)
			var angle: float = direction.angle_to(meshDataTool.get_face_normal(face_index))
			# if angle > PI/2 and angle < PI: # omit hits on backface triangles
			results.append([face_index, intersects_triangle]) # face index, collision point

		i += 3
	
	return results
