extends TextureRect
@export var seedMult = 1
var wait = 0.05
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(wait <= 0):
		var noise_tex = texture as NoiseTexture2D
		noise_tex.noise.seed = randi() * seedMult
			# Required to force regeneration if not changing in _ready
		noise_tex.changed.emit() 
		wait = 0.05
	wait -= delta
