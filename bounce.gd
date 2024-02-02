extends MeshInstance3D

var pos: Vector3
var rot: Vector3
@export var bounce_msec: float = 2000
@export var dpos: Vector3 = Vector3(0, 0.4, 0)
@export var rot_msec: float = 2000
@export var drot: Vector3 = Vector3(0, 2 * PI, 0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pos = transform.origin
	rot = transform.basis.get_euler()
	
	# var tween: Tween

	#tween = create_tween()
	#tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#tween.tween_property($Fur, "height", 0.7, 2.0)
	#tween.tween_property($Fur, "height", 0.05, 2.0)
	#tween.set_loops()
	#
	#tween = create_tween()
	#tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#tween.tween_property($Fur, "gravity", Vector3(0, -1.5, 0), 4.0)
	#tween.tween_property($Fur, "gravity", Vector3(0, 0, 0), 4.0)
	#tween.set_loops()

	# tween = create_tween()
	# tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# tween.tween_property(light, "light_energy", 0, 1.0)
	# tween.tween_property(light, "light_energy", 0, 1.0)
	# tween.tween_property(light, "light_energy", 2.5, 1.0)	
	# tween.set_loops()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.origin = pos + dpos *  abs(sin(Time.get_ticks_msec() / bounce_msec * PI * 2))
	transform.basis = transform.basis.from_euler(
		rot + drot * Time.get_ticks_msec() / rot_msec
	)