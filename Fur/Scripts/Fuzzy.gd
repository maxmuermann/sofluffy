@tool
extends Node

@export
var preview_in_editor: bool = true:
	set(v):
		var previous_value = preview_in_editor
		preview_in_editor = v		
		if Engine.is_editor_hint():
			clear_materials()
			if preview_in_editor:
				create_materials()
				setup_materials()


@export_group("Growth")
	
@export
var number_of_shells: int = 32:
	set(v):
		number_of_shells = v
		clear_materials()
		create_materials()
		setup_materials()
		
@export_range(0, 100, 0.01, "or_greater")
var density: float = 1.0:
	set(v):
		density = v
		setup_materials()
		
@export
var density_texture: Texture2D:
	set(v):
		density_texture = v
		setup_materials()

@export_range(0, 1, 0.001, "or_greater")
var displacement_noise_strength: float = 0.5:
	set(v):
		displacement_noise_strength = v
		setup_materials()
		
@export_range(0, 2, 0.01, "or_greater")
var length: float = 1.0:
	set(v):
		length = v
		setup_materials()
		
@export_range(0, 1, 0.005)
var normal_strength: float = 1.0:
	set(v):
		normal_strength = v
		setup_materials()
		
@export
var static_direction_local: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_local = v
		setup_materials()
		
@export
var static_direction_world: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_world = v
		setup_materials()
		


# Material
@export_group("Material")

@export
var height_gradient: Gradient:
	set(v):
		height_gradient = v
		setup_materials()

## Albedo 
@export_subgroup("Albedo")
@export_color_no_alpha
var albedo_color: Color = Color.DARK_OLIVE_GREEN:
	set(v):
		albedo_color = v
		setup_materials()

@export
var albedo_texture: Texture2D:
	set(v):
		albedo_texture = v
		setup_materials()

@export_subgroup("Emission")


## Emission
@export
var use_emission: bool = false:
	set(v):
		use_emission = v
		setup_materials()
		notify_property_list_changed() # necessary to trigger _validate_property, apparently

@export_color_no_alpha
var emission_color: Color:
	set(v):
		emission_color = v
		setup_materials()

@export_range(0, 16, 0.01)
var emission_energy_multiplier: float = 1.0:
	set(v):
		emission_energy_multiplier = v
		setup_materials()

@export
var emission_texture: Texture2D:
	set(v):
		emission_texture = v
		setup_materials()
		


@export_group("The Rest")

@export
var displacement_noise: Texture2D:
	set(v):
		displacement_noise = v
		setup_materials()
		
@export
var shell_material: Material = load("res://Fur/Materials/fuzzy_shell_material.tres");

@export
var thickness: Curve
		
# physics parameters are set in _process, no need to call setup_materials()
@export var gravity: Vector3 = Vector3(0,0,0)
@export var stiffness: float = 1000
@export var mass: float = 0.001
@export var damping: float = 0.001
@export var stretch: float = 1.0

# the mesh we're growing fur on
var mesh: MeshInstance3D

# the generated shell materials
var shells: Array = []

# linear spring physics variables
var previous_position: Vector3
var spring_offset: Vector3 = Vector3.ZERO
var spring_velocity: Vector3 = Vector3.ZERO

# rotational spring physics variables
var previous_rotation: Vector3 = Vector3.ZERO
var spring_rotation: Vector3 = Vector3.ZERO
var spring_angular_velocity: Vector3 = Vector3.ZERO


func _validate_property(property: Dictionary):
	# hide/show emission section details
	if property.name in ["emission_color", "emission_energy_multiplier", "emission_texture"] and !use_emission:
			property.usage = PROPERTY_USAGE_NO_EDITOR

# Called when the node enters the scene tree for the first time.
func _ready():
	clear_materials()
	create_materials()
	setup_materials()
	
# remove fur material
func clear_materials():
	if(mesh == null): return
	mesh.get_surface_override_material(0).next_pass = null
	for shell in shells:
		shell.next_pass = null
	shells = []

# create cascade of shell materials and assign to subsequent next_pass slots
func create_materials():
	mesh = get_parent()
	if(mesh == null): return	

	var mat = mesh.get_surface_override_material(0)
	
	for i in range(number_of_shells):
		var new_mat = shell_material.duplicate()
		mat.next_pass = new_mat
		mat = new_mat
		shells.append(mat)
		
	previous_position = mesh.transform.origin
	previous_rotation = mesh.transform.basis.get_euler()
		

# setup parameters for all shell materials
func setup_materials():
	if(mesh == null): return

	for i in number_of_shells:
		configure_material_for_level(shells[i], i)

# set shader parameters for a single shell at the given level
func configure_material_for_level(mat: Material, level: int):
	var h = float(level) / (number_of_shells-1)
	var thick = thickness.sample(h)
	
	# growth
	mat.set_shader_parameter("height", length)
	mat.set_shader_parameter("normal_strength", normal_strength)
	mat.set_shader_parameter("static_direction_local", static_direction_local)
	mat.set_shader_parameter("static_direction_world", static_direction_world)
	mat.set_shader_parameter("h", h)
	mat.set_shader_parameter("density_texture", density_texture)
	mat.set_shader_parameter("displacement_noise", displacement_noise)
	mat.set_shader_parameter("displacement_noise_strength", displacement_noise_strength)
	mat.set_shader_parameter("density", density)
	mat.set_shader_parameter("thickness", thick)

	# Albedo
	mat.set_shader_parameter("color", height_gradient.sample(h) * albedo_color)
	mat.set_shader_parameter("use_albedo_texture", albedo_texture != null)
	mat.set_shader_parameter("albedo_texture", albedo_texture)

	# Emission
	mat.set_shader_parameter("use_emission", use_emission)
	mat.set_shader_parameter("emission_color", emission_color)
	mat.set_shader_parameter("emission_energy_multiplier", emission_energy_multiplier)
	mat.set_shader_parameter("use_emission_texture", emission_texture != null)
	mat.set_shader_parameter("emission_texture", emission_texture)

	# initial Physics parameters
	mat.set_shader_parameter("physics_pos_offset", Vector3.ZERO)
	mat.set_shader_parameter("physics_rot_offset", Basis.IDENTITY)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	linear_spring_physics(delta)
	rotational_spring_physics(delta)
	
# calculate physics displacement for linear movement
func linear_spring_physics(delta: float):
	# calculate compound linear forces acting on the shells
	var f = gravity
	
	if !Engine.is_editor_hint():
		# calculate movement from previous position
		var dx = mesh.transform.origin - previous_position # movement from previous position
		var v = dx / delta # velocity
		spring_offset += dx # new offset, after base has moved	
		
		f += -stiffness * spring_offset - damping * (v+spring_velocity)
	
	var a = f / mass
	spring_velocity += a * delta
	var s = spring_velocity * delta / 2
	
	spring_offset += s
	
	# clamp to max length
	var l = spring_offset.length()
	if l > length * stretch:
		spring_offset = spring_offset / l * length
	
	# iterate through materials from 0 length to 1 and set physics params
	var dh = 1.0 / (number_of_shells-1)
	var h = length * dh	

	for i in range(number_of_shells):
		var mat = shells[i]
		var offset_at_height = 8 * spring_offset * h * pow(i, 1.1)
		mat.set_shader_parameter("physics_pos_offset", -offset_at_height)
		i+=1
		
	previous_position = mesh.transform.origin


# calculate physics displacement for rotational movement
func rotational_spring_physics(delta: float):
	# calculate compound rotational forces acting on the shells, as a Vector3 of Euler angles
	var f = Vector3.ZERO
	
	if !Engine.is_editor_hint():
		# calculate rotation from previous position
		var dp: Vector3 = mesh.transform.basis.get_euler() - previous_rotation # rotation from previous rotation
		var w: Vector3 = dp / delta # velocity
		spring_rotation += dp # new offset, after base has rotated
		
		f += -spring_rotation * stiffness - damping * (w+spring_angular_velocity)
	
	var a = f / mass
	spring_angular_velocity += a * delta
	var p = spring_angular_velocity * delta / 2
	
	spring_rotation += p
	
	# clamp to max rotation
	var l = spring_rotation.length()
	if l > PI / 8:
		spring_rotation = spring_rotation / l * PI / 8
	
	# iterate through materials from 0 length to 1 and set physics params
	var dh = 1.0 / (number_of_shells-1)
	var h = length * dh	

	for i in range(number_of_shells):
		var mat = shells[i]
		var rotation_at_height = spring_rotation * h * i * 10
		mat.set_shader_parameter("physics_rot_offset", Basis.from_euler(rotation_at_height))
		i+=1
		
	previous_rotation = mesh.transform.basis.get_euler()
