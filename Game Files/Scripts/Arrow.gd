extends Area2D

@export var damage = 20
var can_damage = true

var mass = 1.0
var speed = 700
var arrow_direction
var rotator: float
var velocity = Vector2(0, 0)

@rpc("any_peer", "unreliable")
func _sync_transform(remote_pos: Vector2, remote_rot: float) -> void:
	if not is_multiplayer_authority():
		global_position = remote_pos
		rotation = remote_rot

func _ready() -> void:
	# ← connect takes the signal name and a Callable now
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _physics_process(delta):
	if velocity:
		look_at(global_position + velocity.normalized())
	velocity += gravity_direction*gravity*mass*delta
		
	position += velocity*delta
	#position -= arrow_direction * speed * delta
	rotation = rotator
	rotation = velocity.angle()
	
	if is_multiplayer_authority():
		rpc("_sync_transform", global_position, rotation)
	
func launch(initial_velocity : Vector2):
	velocity = initial_velocity

func _on_body_entered(body):
	print("Arrow hit something: ", body.name if body else "unknown")
	
	if body is TileMap:
		print("Arrow hit TileMap")
		mass = 0
		speed = 0
		gravity = 0
		velocity = Vector2.ZERO
		can_damage= false
		
	if body.is_in_group("Player") and can_damage:
		print("Arrow hit Player: ", body.name)
		print("Player has take_damage method: ", body.has_method("take_damage"))
		
		if body.has_method("take_damage"):
			print("Calling take_damage function")
			body.take_damage(damage)
			
			# Also sync damage to other peers
			body.rpc("take_damage", damage)
		else:
			print("Player doesn't have take_damage method!")
		queue_free()
