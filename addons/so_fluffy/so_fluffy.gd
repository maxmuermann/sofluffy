@tool
extends Node

## Show fur in editor. Fur rendering is relatively expensive, so it is recommened to disable this when not needed.
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
				init_physics()


## Parameters that affect the growth of the fur - density, length, jitter, etc.
@export_group("Shape")

## Number of shells to generate. Higher numbers look better, but incur larger performance penalties.
@export
var number_of_shells: int = 64:
	set(v):
		number_of_shells = v
		clear_materials()
		create_materials()
		setup_materials()

## Strand length
@export_range(0, 2, 0.01, "or_greater")
var length: float = 0.1:
	set(v):
		length = v
		setup_materials()

## Scaling of the fur density texture. Higher numbers make the fur more dense.
@export_range(0, 10, 0.01, "or_greater")
var density: float = 1.0:
	set(v):
		density = v
		setup_materials()

## Fur density (length) texture. Values scale hair length by [1..0[. Black pixels are not rendered.
@export
var density_texture: Texture2D = preload("res://addons/so_fluffy/density_default.tres").duplicate():
	set(v):
		density_texture = v
		setup_materials()

## Thickness profile of a single strand. The values are inverted (1 it thin, 0 is thick) so that the curve presets can be used.
@export
var thickness: Curve = preload("res://addons/so_fluffy/thickness_default.tres").duplicate():
	set(v):
		thickness = v
		setup_materials()

## Noise texture to overlay higher-frequency jitter on the fur. Best provided as a normal map.
@export
var jitter_texture: Texture2D = preload("res://addons/so_fluffy/jitter_default.tres").duplicate():
	set(v):
		jitter_texture = v
		setup_materials()	
		
## Strength of the jitter effect. Higher numbers apply more jitter.
@export_range(0, 1, 0.001, "or_greater")
var jitter_strength: float = 0.3:
	set(v):
		jitter_strength = v
		setup_materials()

## Blends the fur growth direction between the surface normal and the static directions below. A value of 1 means fur grows only in the direction of normals, a value of 0 means it grows only in a static direction.
@export_range(0, 1, 0.005)
var normal_strength: float = 1.0:
	set(v):
		normal_strength = v
		setup_materials()

## Static direction of fur growth in object space. This is useful for fur that grows in a specific direction but moves with the object, such as a mane or a mohawk.
@export
var static_direction_local: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_local = v
		setup_materials()
		
## Static direction of fur growth in world space. This is useful for fur that grows in a specific direction in world coordinates, such as grass, which always grows upwards.
@export
var static_direction_world: Vector3 = Vector3.ZERO:
	set(v):
		static_direction_world = v
		setup_materials()
		


# Material parameters
@export_group("Appearance")

var shell_material: Material = preload("res://addons/so_fluffy/shell_material.tres").duplicate(true);

## Albedo color is multiplied by this gradient, sampled by relative height. The default gradient simulates ambient occlusion.
@export
var height_gradient: Gradient = Gradient.new():
	set(v):
		height_gradient = v
		setup_materials()

## Albedo 
@export_subgroup("Albedo")
## Plain hair color
@export_color_no_alpha
var albedo_color: Color = Color.DARK_OLIVE_GREEN:
	set(v):
		albedo_color = v
		setup_materials()

## Texture defining hair color. Albedo color is [i]multiplied[\i] by the texture color.
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

## Uniform emission color
@export_color_no_alpha
var emission_color: Color:
	set(v):
		emission_color = v
		setup_materials()

## Emission energy multiplier. Higher numbers make the emission brighter.
@export_range(0, 16, 0.01)
var emission_energy_multiplier: float = 1.0:
	set(v):
		emission_energy_multiplier = v
		setup_materials()

## Texture defining emission color. Emission color is [i]added[i] to the texture color.
@export
var emission_texture: Texture2D:
	set(v):
		emission_texture = v
		setup_materials()
		

@export_group("Physics")

# physics parameters are set in _process, no need to call setup_materials()
@export var physics_enabled: bool = true:
	set(v):
		physics_enabled = v		
		init_physics()
		notify_property_list_changed()

## Simulate physics in the editor. Physics simulation is very cheap, but can be distracting while editing.
@export var physics_preview: bool = true:
	set(v):
		physics_preview = v
		if(!physics_preview):
			setup_materials()
			init_physics()
## gravity constant
@export var gravity: Vector3 = Vector3(0,0,0)
## hair spring stiffness
@export var stiffness: float = 80
## hair mass - higher numbers make the hair more resistant to movement
@export var mass: float = 0.15
## spring damping
@export var damping: float = 3
## allow hair to stretch beyond its length for a more elastic appearance. A value of 1 means no stretch is allowed.
@export_range(1, 2, 0.01, "or_greater") var stretch: float = 1.0

# the geometry we're growing fur on
var mesh: GeometryInstance3D

# the generated shell materials
var shells: Array = []

# linear spring physics state
var previous_position: Vector3
var spring_offset: Vector3 = Vector3.ZERO
var spring_velocity: Vector3 = Vector3.ZERO

# rotational spring physics state
var previous_rotation: Vector3 = Vector3.ZERO
var spring_rotation: Vector3 = Vector3.ZERO
var spring_angular_velocity: Vector3 = Vector3.ZERO

func _validate_property(property: Dictionary):
	# hide/show emission section details
	if property.name in ["emission_color", "emission_energy_multiplier", "emission_texture"] and !use_emission:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	# hide/show physics section details
	if property.name in ["physics_preview", "gravity", "stiffness", "mass", "damping", "stretch"] and !physics_enabled:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready():
	if density_texture.noise == null:
		density_texture.noise = FastNoiseLite.new()
	init_physics()


func _enter_tree():
	clear_materials()
	create_materials()
	setup_materials()
	notify_property_list_changed()


# remove fur material
func clear_materials():
	if(mesh == null): return
	mesh.material_overlay = null
	for shell in shells:
		shell.next_pass = null
	shells = []


# create cascade of shell materials and assign to subsequent next_pass slots
func create_materials():
	mesh = get_parent()
	if(mesh == null): return	

	var mat = shell_material.duplicate()
	mesh.material_overlay = mat
	shells.append(mat)

	for i in range(1, number_of_shells):
		var new_mat = shell_material.duplicate()
		mat.next_pass = new_mat
		mat = new_mat
		shells.append(mat)
		
	previous_position = mesh.transform.origin
	previous_rotation = mesh.transform.basis.get_euler()
		

# setup parameters for all shell materials
func setup_materials():
	if mesh == null: return

	for i in number_of_shells:
		configure_material_for_level(shells[i], i)


# set shader parameters for a single shell at the given level
func configure_material_for_level(mat: Material, level: int):
	# var h = float(level) / (number_of_shells-1)
	var h = float(level) / (number_of_shells-1)
	var thick = thickness.sample(h)
	# growth
	mat.set_shader_parameter("height", length)
	mat.set_shader_parameter("normal_strength", normal_strength)
	mat.set_shader_parameter("static_direction_local", static_direction_local)
	mat.set_shader_parameter("static_direction_world", static_direction_world)
	mat.set_shader_parameter("h", h)
	mat.set_shader_parameter("density_texture", density_texture)
	mat.set_shader_parameter("jitter_texture", jitter_texture)
	mat.set_shader_parameter("jitter_strength", jitter_strength)
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

func init_physics():
	spring_offset = Vector3.ZERO
	spring_velocity = Vector3.ZERO
	spring_rotation = Vector3.ZERO
	spring_angular_velocity = Vector3.ZERO	

	if mesh == null: return

	previous_position = mesh.transform.origin
	previous_rotation = mesh.transform.basis.get_euler()

	for mat in shells:
		# initial Physics parameters
		mat.set_shader_parameter("physics_pos_offset", Vector3.ZERO)
		mat.set_shader_parameter("physics_rot_offset", Basis.IDENTITY)


func _physics_process(delta):	
	linear_spring_physics(delta)
	rotational_spring_physics(delta)

# calculate spring physics for linear movement
func linear_spring_physics(delta: float):
	if !physics_enabled: return
	if Engine.is_editor_hint() and (!physics_preview || !preview_in_editor): return
	# calculate compound linear forces acting on the shells
	var f = gravity
		
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
	var h = dh	

	for i in range(number_of_shells):
		var mat = shells[i]
		var offset_at_height = 8 * spring_offset * pow(h * i, 1.0/length)
		mat.set_shader_parameter("physics_pos_offset", -offset_at_height)
		i+=1
		
	previous_position = mesh.transform.origin


# calculate spring physics for rotational movement
func rotational_spring_physics(delta: float):
	if !physics_enabled: return
	if Engine.is_editor_hint() and (!physics_preview || !preview_in_editor): return
	# calculate compound rotational forces acting on the shells, as a Vector3 of Euler angles
	var f = Vector3.ZERO
	
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
	var maxL = PI * length / 2.0
	if l > maxL:
		spring_rotation = spring_rotation / l * maxL
	
	# iterate through materials from 0 length to 1 and set physics params
	var dh = 1.0 / (number_of_shells-1)
	var h = dh	

	for i in range(number_of_shells):
		var mat = shells[i]
		var rotation_at_height = spring_rotation * pow(h * i, 1.0 / length)
		mat.set_shader_parameter("physics_rot_offset", Basis.from_euler(rotation_at_height))
		i+=1
		
	previous_rotation = mesh.transform.basis.get_euler()
