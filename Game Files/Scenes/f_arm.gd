extends AnimatedSprite2D


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	var mouse_position = get_global_mouse_position()

	if mouse_position.x > global_position.x:
		flip_v = false
		position.x = -2.667
		$hand.position.y = abs($hand.position.y)
		rotation_degrees = 45
	elif mouse_position.x < global_position.x:
		flip_v = true
		position.x = 4.2
		$hand.position.y = abs($hand.position.y) * -1
		
	look_at(get_global_mouse_position())
	#if Input.is_action_just_pressed("fire") and $"../..".can_fire == true:
		#self.play("attack")
		
	if Input.is_action_pressed("fire") == false:
		self.play("initial_state")
