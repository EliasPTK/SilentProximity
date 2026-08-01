extends Sprite3D

var my_texture: Texture2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat = material_override.duplicate()
	material_override = mat
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	my_texture = $"../Node2D".get_child(0).texture
	if(my_texture != null):
		texture = my_texture
		var mat = material_override as StandardMaterial3D
		
		mat.albedo_texture = my_texture
		mat.emission_texture = my_texture
