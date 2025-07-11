extends TextureProgressBar
@onready var player = $"../.."


func _ready():
	if is_multiplayer_authority():
		player.healthChanged.connect(update)
		update()
	
	
func update():
	value = player.hp * 100 / player.max_hp
