extends SubViewport

@export var brush: Sprite2D
@export var clearRect: ColorRect

var dirty = false

func _ready():
	brush = $Brush	

func move_brush(position : Vector2):
	if !dirty:
		clearRect.visible = false
		dirty = true
	set_update_mode(UPDATE_ONCE)	
	brush.set_position(Vector2(position.x * size.x, position.y * size.y))

func brush_size():
	return brush.texture.get_height()
