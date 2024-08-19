@tool
extends EditorPlugin

const AUTOLOAD_NAME := "DepthBufferManager"

func _enter_tree() -> void:
	# Add the manager script as an autoload.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/depth_buffer/depth_buffer_manager.gd")


func _exit_tree() -> void:
	# Remove the manager script.
	remove_autoload_singleton(AUTOLOAD_NAME)
