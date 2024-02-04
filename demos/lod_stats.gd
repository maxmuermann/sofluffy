extends Label

@export var fur: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = "LOD lvl: %s, shells: %s" % [fur.lod, fur.lod_shell_count]
