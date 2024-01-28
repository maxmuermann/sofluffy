@tool
extends Node

@export var apply: bool = false:
	set(v):
		setup_materials()
@export var number_of_shells: int = 32:
	set(v):
		number_of_shells = v
		clear_materials()
		create_materials()
		setup_materials()
@export_range(0, 100, 0.05, "or_greater") var density: float = 1.0:
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
@export_range(0, 1, 0.005, "or_greater") var displacement_noise_strength: float = 0.5:
	set(v):
		displacement_noise_strength = v
		setup_materials()
@export_range(0, 2, 0.05, "or_greater") var height: float = 1.0:
	set(v):
		height = v
		setup_materials()
@export_range(0, 1, 0.005)  var normal_strength: float = 1.0:
	set(v):
		normal_strength = v
		setup_materials()
@export var static_direction_local: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_local = v
		setup_materials()
@export var static_direction_world: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_world = v
		setup_materials()
@export var height_gradient: Gradient:
	set(v):
		height_gradient = v
		setup_materials()
@export var shell_material: Material = load("res://Fur/Materials/fuzzy_shell_material.tres");
@export var thickness: Curve
@export var tint: Color = Color.DARK_OLIVE_GREEN:
	set(v):
		tint = v
		setup_materials()
# physics parameters are set in process, no need to setup materials for this
@export var gravity: Vector3 = Vector3(0,-1,0)
@export var dynamic: bool = false

var mesh: MeshInstance3D
var shells: Array = []


var previous_position: Vector3;
var previous_dpos: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	clear_materials()
	create_materials()
	setup_materials()
	
	
func clear_materials():
	if(mesh == null): return
	mesh.get_surface_override_material(0).next_pass = null
	for shell in shells:
		shell.next_pass = null
	shells = []


func create_materials():
	mesh = get_parent()
	if(mesh == null): return	
	previous_position = mesh.transform.origin	

	var mat = mesh.get_surface_override_material(0)
	
	for i in range(number_of_shells):
		var new_mat = shell_material.duplicate()
		mat.next_pass = new_mat
		mat = new_mat
		shells.append(mat)
		
		
func setup_materials():
	if(mesh == null): return

	for i in number_of_shells:
		configure_material_for_level(shells[i], i)


func configure_material_for_level(mat: Material, level: int):
	mat.set_shader_parameter("height", height)
	mat.set_shader_parameter("normal_strength", normal_strength)
	mat.set_shader_parameter("static_direction_local", static_direction_local)
	mat.set_shader_parameter("static_direction_world", static_direction_world)
	
	var h = float(level) / (number_of_shells-1)
	mat.set_shader_parameter("h", h)
	mat.set_shader_parameter("base_texture", base_texture)
	mat.set_shader_parameter("displacement_noise", displacement_noise)
	mat.set_shader_parameter("displacement_noise_strength", displacement_noise_strength)
	mat.set_shader_parameter("density", density)
	var thick = thickness.sample(h)
	mat.set_shader_parameter("thickness", thick)	
	mat.set_shader_parameter("color", height_gradient.sample(h) * tint)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var disp = gravity
	
	#var m = get_parent()
	
	if(dynamic):
		# calculate movement from previous position
		var dpos = mesh.transform.origin - previous_position
		dpos *= 30.0
		
		var act: Vector3 = lerp(previous_dpos, dpos, 0.3) # <0.1 looks like it's underwater
		
		var l = act.length()
		if l > height:
			act = act / l * height
		
		disp -= act
		previous_dpos = act
	
	previous_position = mesh.transform.origin
	
	# iterate through materials from 0 height to 1 and set physics params
	var dh = 1.0 / (number_of_shells-1)
	var h = height * dh	

	for i in range(number_of_shells):
		var mat = shells[i]
		var disp_at_height = disp * h * pow(i, 1.2)
		mat.set_shader_parameter("physics_pos_offset", disp_at_height)
		i+=1
