extends MeshInstance3D

var pos: Vector3
var rot: Vector4
@export var dist: float = 1.0
@export var period: float = 1.0

@export var light: Light3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pos = transform.origin
	
	var tween: Tween

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
	return
	# transform.origin = pos + Vector3(0, 0.1, 0) *  abs(sin(Time.get_ticks_msec() / 1200.0 * period * PI * 2))
	# transform.basis = transform.basis.from_euler(
	# 	Vector3(
	# 		0.1, #0.4 * sin(Time.get_ticks_msec() / 400.0 * period * PI * 2),
	# 		2.5 + 0.6 * sin(Time.get_ticks_msec() / 2400.0 * period * PI * 2),
	# 		0.1 * sin(Time.get_ticks_msec() / 1200.0 * period * PI * 2)
	# 	)
	# )	
