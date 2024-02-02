extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.tween_interval(2)
	t.tween_property(self, "position", Vector3(0,-0.5,-19), 8).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(self, "rotation", Vector3(0,-0.4, 0), 8).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(get_node("../Camera3D"), "rotation", Vector3(-0.4,0,0), 8).set_trans(Tween.TRANS_EXPO)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
