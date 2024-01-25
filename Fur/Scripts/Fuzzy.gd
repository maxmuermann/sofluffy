@tool
extends Node

@export var apply: bool = false:
	set(v):
		setup_materials()
@export var number_of_shells: int = 32:
	set(v):
		number_of_shells = v
		setup_materials()
@export var density: float = 1.0:
	set(v):
		density = v
		setup_materials()
@export var base_texture: Texture2D:
	set(v):
		base_texture = v
		setup_materials()
@export var displacement_noise: Texture2D:
	set(v):
		displacement_noise = v
		setup_materials()
@export var displacement_noise_strength: float = 0.5:
	set(v):
		displacement_noise_strength = v
		setup_materials()
@export var height: float = 1.0:
	set(v):
		height = v
		setup_materials()
@export var height_gradient: Gradient:
	set(v):
		height_gradient = v
		setup_materials()
@export var shell_material: Material = load("res://Fur/Materials/fuzzy_shell_material.tres");
@export var thickness: Curve:
	set(v):
		thickness = v
		setup_materials()
@export var tint: Color = Color.DARK_OLIVE_GREEN:
	set(v):
		tint = v
		setup_materials()
# physics parameters are set in process, no need to setup materials for this
@export var gravity: Vector3 = Vector3(0,-1,0)
@export var dynamic: bool = false

var mesh: MeshInstance3D

var previous_position: Vector3;
var previous_dpos: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh = get_parent()
	clear_materials()
	setup_materials()
	previous_position = mesh.transform.origin
	
func clear_materials():
	mesh.set_surface_override_material(0, null)
	
func material_for_level(level: int):
	var mat: ShaderMaterial = shell_material.duplicate()
	mat.set_shader_parameter("height", height)
	
	var h = float(level) / (number_of_shells-1)
	mat.set_shader_parameter("h", h)
	mat.set_shader_parameter("base_texture", base_texture)
	mat.set_shader_parameter("displacement_noise", displacement_noise)
	mat.set_shader_parameter("displacement_noise_strength", displacement_noise_strength)
	mat.set_shader_parameter("density", density)
	var thick = thickness.sample(h)
	mat.set_shader_parameter("thickness", thick)	
	mat.set_shader_parameter("color", height_gradient.sample(h) * tint)
	return mat
	
func setup_materials():
	if(mesh == null):
		return
	# shell 0	
	var mat = material_for_level(0)
	mesh.set_surface_override_material(0, mat)
	
	for i in range(1, number_of_shells):
		var new_mat: ShaderMaterial = material_for_level(i)
		mat.next_pass = new_mat
		mat = new_mat

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var disp = gravity
	
	if(dynamic):
		# calculate movement from previous position
		var dpos = mesh.transform.origin - previous_position
		dpos *= 30		
		
		var act = lerp(previous_dpos, dpos, 0.5)
		
		disp -= act
		previous_dpos = act
	
	previous_position = mesh.transform.origin
	
	# iterate through materials from 0 height to 1 and set physics params
	var mat:ShaderMaterial = mesh.get_surface_override_material(0)
	var h = height / number_of_shells	
	var i = 0

	while(mat != null):
		var disp_at_height = disp * pow(h * i, 2)
		mat.set_shader_parameter("physics_pos_offset", disp_at_height)
		mat = mat.next_pass
		i+=1

