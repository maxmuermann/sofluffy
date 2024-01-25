extends MeshInstance3D

var pos: Vector3
var rot: Vector4
@export var dist: float = 1.0
@export var period: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pos = transform.origin	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#return
	transform.origin = pos + Vector3(0, 1, 0) *  sin(Time.get_ticks_msec() / 1000.0 * period * PI * 2)
	#transform.basis = transform.basis.from_euler(Vector3(45.0, Time.get_ticks_msec() / 1000.0, 0))
