extends TextureProgressBar
@onready var player = $"../.."


func _ready():
	player.healthChanged.connect(update)
	update()
	
	
func update():
	value = player.hp * 100 / player.max_hp
