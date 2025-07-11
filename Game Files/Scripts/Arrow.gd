extends Area2D

@export var damage = 20
var can_damage = true

var mass = 1.0
var speed = 700
var arrow_direction
var rotator: float
var velocity = Vector2(0, 0)
var owner_id: int = -1

# 1️⃣ Change your sync RPC so the *authority* can push updates to *others*:
@rpc("call_remote", "authority", "unreliable")
func _sync_transform(remote_pos: Vector2, remote_rot: float) -> void:
	global_position = remote_pos
	rotation = remote_rot

# 2️⃣ Add a “destroy on all peers” RPC
@rpc("call_remote", "authority", "reliable")
func _destroy() -> void:
	queue_free()

func _ready() -> void:
	# ← connect takes the signal name and a Callable now
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _physics_process(delta: float) -> void:
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


# 3️⃣ When we hit something, tell everyone to destroy this arrow
func _on_body_entered(body: Node) -> void:
	if is_multiplayer_authority():
		if body.has_method("rpc_take_damage") and can_damage:
			# Tell each client’s player instance to take damage
			body.rpc("rpc_take_damage", damage)
		rpc("_destroy")
		queue_free()
