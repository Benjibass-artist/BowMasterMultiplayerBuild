extends CharacterBody2D
# Declare member variables here. Examples:
var speed = 250.0  # Horizontal movement speed in pixels per second
var gravity = 1200.0  # Gravity in pixels per second squared
var jump_force = -500.0  # Upward force for jumping
var wall_slide_speed = 150.0  # Slower gravity when sliding down a wall
var wall_jump_force = 350.0  # Reduced horizontal force when jumping off the wall
var double_jump_allowed = true  # Allow double jump globally
var can_double_jump = false  # State to check if double jump can be used, initially false
var wall_jump_time = 0.2  # Time over which the wall jump force is applied
var wall_jump_timer = 0.0  # Timer to track the application of the jump force
var just_left_ground = false  # To track if the player just left the ground without jumping
@export var arrow_scene = preload("res://Scenes/arrow_projectile.tscn")
#@onready var bowCharge = $BowCharge
@export var can_fire = true
signal healthChanged

@export var hp = 100
@export var max_hp = 100
var player_alive = true
var death_animation_finished = false
var death_animation_played = true

var charge_finished = false
var test : float = 0 : set = _set_value
#variable for the bow charging
var increment = 0.0
#multiplayer instantiated player camera
@onready var cam = $Camera2D



@export var arrow_speed: float = 700



func _ready():
	#check is user owns a character so they view own player through correct camera
	cam.enabled = is_multiplayer_authority()
	#set spawn location once player joins
	

func _physics_process(delta):
	#cannot cntrol other players
	if !is_multiplayer_authority():
		return
	
	# Handle input
	var input_vector = Vector2.ZERO
	if hp <= 0:
		player_alive = false     # death logic
		#death trigger animation and process
		if hp <=0:
			player_alive = false
		if !player_alive:
			$CollisionShape2D.hide()
			$bodyAnimation/b_arm.hide()
			$bodyAnimation/frontArm.hide()
			if !death_animation_finished and death_animation_played:
				$bodyAnimation.play("death")
				death_animation_played = false
	if hp < 99:
		healthChanged.emit()
	death_animation_finished = false

	if Input.is_action_pressed("ui_right") and player_alive:
		input_vector.x = 1.0
		$bodyAnimation.flip_h = false
	elif Input.is_action_pressed("ui_left") and player_alive:
		input_vector.x = -1.0
		$bodyAnimation.flip_h = true
	
	# Apply horizontal velocity based on input outside of wall jump
	if wall_jump_timer <= 0:
		velocity.x = input_vector.x * speed
			
	#movement animation player
	if velocity.x == 0 and is_on_floor() and player_alive:
		$bodyAnimation.play("idle")
	elif velocity.x != 0 and is_on_floor() and player_alive:
		$bodyAnimation.play("run")
	if is_on_wall() and not is_on_floor() and player_alive:
		$bodyAnimation.play("wallslide")
	if Input.is_action_just_pressed("ui_accept") and double_jump_allowed == true and player_alive:
			$bodyAnimation.play("jump")
	
	# Apply gravity
	if is_on_wall() and !is_on_floor() and velocity.y > 0:
		# Reduce gravity if on a wall and not on the floor to simulate wall sliding
		velocity.y += wall_slide_speed * delta
		if not can_double_jump:  # Restore one jump when colliding with a wall
			can_double_jump = true
	else:
		velocity.y += gravity * delta

	# Detect if just left the ground without jumping
	if is_on_floor():
		just_left_ground = true
	elif just_left_ground:
		can_double_jump = true
		just_left_ground = false
		
	
	if Input.is_action_just_pressed("ui_accept") and player_alive:
			$bodyAnimation.play("jump")

	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and player_alive:
		if is_on_floor():
			velocity.y = jump_force
			can_double_jump = true  # Reset double jump when on floor
			just_left_ground = false
		elif is_on_wall() and not is_on_floor():
			# Start wall jump
			velocity.y = jump_force
			wall_jump_timer = wall_jump_time
			velocity.x = -input_vector.x * wall_jump_force  # Initial impulse away from the wall
			can_double_jump = true  # Restore a double jump ability after a wall jump
		elif can_double_jump:
			velocity.y = jump_force
			can_double_jump = false  # Use up the double jump

	# Gradually reduce the horizontal speed after wall jump
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta / wall_jump_time)  # Smoothly reduce to zero

	# Move the character
	if(Input.is_action_pressed("ui_down") and (is_on_floor()) and player_alive):
		position.y += 5  # Move the character down when pressing down on the floor
		
	
	
	if Input.is_action_pressed("fire") and can_fire and player_alive:
		increment += 0.02
		if !charge_finished:
			$bodyAnimation/frontArm.play("attack")
		_set_value(increment)
		print(test)
	else:
		increment = 0
		charge_finished = false
	if Input.is_action_just_released("fire") and can_fire and player_alive:
		can_fire = false
		$AttackInterval.start()
		shoot()
		increment = 0
		#bowCharge.value = 0

	move_and_slide()
	
func _set_value(value):
	test = clamp(value,0,1.3)

#attack function for arrow
@rpc("authority")
func spawn_arrow(pos: Vector2, vel: Vector2, rot: float) -> void:
	# skip on the original shooter (optional)
	if is_multiplayer_authority():
		return

	var arrow = arrow_scene.instantiate()
	add_child(arrow)
	arrow.global_position = pos
	arrow.launch(vel)
	arrow.rotation = rot
func shoot():
	var arrow = arrow_scene.instantiate()
	arrow.position = $bodyAnimation/frontArm/hand.global_position
	arrow.rotator = $bodyAnimation/frontArm/hand.global_rotation
	arrow.arrow_direction = (position - get_global_mouse_position()).normalized()
	
	arrow.velocity = global_position.direction_to(get_global_mouse_position()) * arrow.speed * test
	arrow.owner_id = get_multiplayer_authority()
	get_parent().add_child(arrow)
	
	rpc("spawn_arrow", arrow.global_position, arrow.velocity, arrow.rotation)

@rpc("any_peer")
func rpc_take_damage(amount: int) -> void:
	if not get_tree().is_server():
		return
	hp -= amount
	healthChanged.emit()
	print(hp)
	
func _shoot_arrow(initial_velocity: Vector2) -> void:
	# 1) locally spawn the arrow
	var arrow = arrow_scene.instantiate()
	add_child(arrow)
	arrow.global_position = $bodyAnimation/frontArm/hand.global_position
	arrow.launch(initial_velocity)

	# 2) tell every other peer to do the same
	rpc("spawn_arrow", arrow.global_position, initial_velocity, arrow.rotation)

# Helper function to perform linear interpolation
func lerp(start, end, weight):
	return start + (end - start) * weight



func _on_attack_interval_timeout():
	can_fire = true


func _on_front_arm_animation_finished():
	charge_finished = true


func _on_body_animation__finished():
	#stopping the death animation loop in the physics process
	if $bodyAnimation.animation == "death":
		if $bodyAnimation.frame == 4:
			$bodyAnimation.pause()
	pass # Replace with function body.
