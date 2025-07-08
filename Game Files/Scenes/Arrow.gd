extends Area2D

@export var damage = 20
var can_damage = true

var mass = 1.0
var speed = 700
var arrow_direction
var rotator: float
var velocity = Vector2(0, 0)


func _ready() -> void:
	# ← connect takes the signal name and a Callable now
	body_entered.connect(_on_body_entered)
func _process(delta):
	if velocity:
		look_at(global_position + velocity.normalized())
	velocity += gravity_direction*gravity*mass*delta
		
	position += velocity*delta
	#position -= arrow_direction * speed * delta
	rotation = rotator
	rotation = velocity.angle()
	
func launch(initial_velocity : Vector2):
	velocity = initial_velocity


func _on_body_entered(body):
	if not is_multiplayer_authority():
		return
	if body is TileMap:
		mass = 0
		speed = 0
		gravity = 0
		velocity = -(arrow_direction)
		#velocity = Vector2.ZERO
		can_damage= false
	if not is_multiplayer_authority():
		return

	if body.has_method("rpc_take_damage"):
		var target_peer = body.get_multiplayer_authority()
		rpc_id(target_peer, "rpc_take_damage", damage)
	
	queue_free()
