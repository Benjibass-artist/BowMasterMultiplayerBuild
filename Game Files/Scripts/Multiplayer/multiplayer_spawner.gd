extends MultiplayerSpawner

@export var playerScene : PackedScene
func _ready():
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)
	

var players = {}

func spawnPlayer(data):
	var p = playerScene.instantiate()
	p.set_multiplayer_authority(data) 
	players[data] = p
	p.position = choose_spawn_location()
	return p
	
var spawn_points = [Vector2(-550, 600), Vector2(1600, 600),]
var duplicate_spawn_points = spawn_points
var invalid_points = []
	
func choose_spawn_location():
	var point = randi()%spawn_points.size()
	var spawn_location = spawn_points[point]
	invalid_points.append(spawn_location)
	spawn_points.erase(point)
	return spawn_location
	
func removePlayer(data):
	players[data].queue_free()
	players.erase(data)
