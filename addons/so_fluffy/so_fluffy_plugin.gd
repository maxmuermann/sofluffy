@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("Fur", "Node", preload("so_fluffy.gd"), preload("icon.svg"))



func _exit_tree():
	# Clean-up of the plugin goes here.
	pass
