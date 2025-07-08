extends Sprite2D

func _physics_process(delta):
	var mouse_position = get_global_mouse_position()

	if mouse_position.x > global_position.x:
		flip_v = false
	elif mouse_position.x < global_position.x:
		flip_v = true
		
	look_at(get_global_mouse_position())
